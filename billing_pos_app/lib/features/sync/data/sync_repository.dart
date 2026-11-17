import "dart:convert";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite/sqflite.dart";
import "package:uuid/uuid.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/sync_models.dart";

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return SyncRepository(dioClient, db);
});

class SyncRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  SyncRepository(this._dioClient, this._db);

  Future<ApiResponse<DeviceStatusModel>> registerDevice({
    required String deviceId,
    required String deviceName,
    String appVersion = "1.0.0",
    bool isOnline = true,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.syncRegisterDevice,
        data: {
          "deviceId": deviceId,
          "deviceName": deviceName,
          "appVersion": appVersion,
          "isOnline": isOnline,
        },
      );

      if (response.success && response.data != null) {
        final model = DeviceStatusModel.fromJson(response.data as Map<String, dynamic>);
        await _saveLocalDeviceState(model);
        return ApiResponse<DeviceStatusModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<DeviceStatusModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<DeviceStatusModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<DeviceStatusModel>> getDeviceStatus(String deviceId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.syncStatus,
        queryParameters: {"deviceId": deviceId},
      );

      if (response.success && response.data != null) {
        final model = DeviceStatusModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<DeviceStatusModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<DeviceStatusModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<DeviceStatusModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<SyncPushResultModel>> pushBatch({
    required String deviceId,
    required String appVersion,
    List<Map<String, dynamic>> customers = const [],
    List<Map<String, dynamic>> invoices = const [],
  }) async {
    try {
      final db = await _db.database;
      final invoicesPayload = List<Map<String, dynamic>>.from(invoices);
      final syncedInvoiceIds = <int>[];

      // If no explicit invoices supplied, gather all unsynced invoices from local SQLite
      if (invoicesPayload.isEmpty) {
        final unsynced = await db.query(
          DatabaseTables.localInvoice,
          where: "SyncStatus = 0 AND InvoiceStatus != 3",
        );

        for (final row in unsynced) {
          final invId = (row["InvoiceId"] as num).toInt();
          syncedInvoiceIds.add(invId);

          final itemRows = await db.query(
            DatabaseTables.localInvoiceDetail,
            where: "InvoiceId = ?",
            whereArgs: [invId],
          );
          final payRows = await db.query(
            DatabaseTables.localPayment,
            where: "InvoiceId = ?",
            whereArgs: [invId],
          );

          invoicesPayload.add({
            "invoiceGuid": row["InvoiceGuid"]?.toString() ?? const Uuid().v4(),
            "invoiceNumber": row["InvoiceNumber"],
            "customerId": row["CustomerId"],
            "customerGuid": null,
            "cashierId": row["CashierId"] ?? 1,
            "invoiceDateUtc": row["InvoiceDateUTC"],
            "subTotal": row["SubTotal"],
            "discountAmount": row["DiscountAmount"],
            "taxableAmount": row["TaxableAmount"],
            "taxAmount": row["TaxAmount"],
            "grandTotal": row["GrandTotal"],
            "paidAmount": row["PaidAmount"],
            "balanceAmount": row["BalanceAmount"],
            "paymentStatus": row["PaymentStatus"],
            "invoiceStatus": row["InvoiceStatus"],
            "items": itemRows.map((it) => {
              "productId": it["ProductId"],
              "productNameSnapshot": it["ProductNameSnapshot"],
              "unitPrice": it["UnitPrice"],
              "quantity": (it["Quantity"] as num).toInt(),
              "discountAmount": it["DiscountAmount"],
              "taxPercentage": it["TaxPercentage"],
              "taxAmount": it["TaxAmount"],
              "lineTotal": it["LineTotal"],
            }).toList(),
            "payments": payRows.map((p) => {
              "paymentGuid": p["PaymentGuid"]?.toString() ?? const Uuid().v4(),
              "paymentMode": p["PaymentModeId"] ?? 1,
              "amount": p["Amount"],
              "transactionReference": p["TransactionReference"],
              "paymentStatus": p["PaymentStatus"] ?? 2,
              "createdAtUtc": p["CreatedAtUTC"] ?? DateTime.now().toUtc().toIso8601String(),
            }).toList(),
          });
        }
      }

      final response = await _dioClient.post(
        ApiEndpoints.syncPush,
        data: {
          "deviceId": deviceId,
          "appVersion": appVersion,
          "clientSyncTimestampUtc": DateTime.now().toUtc().toIso8601String(),
          "customers": customers,
          "invoices": invoicesPayload,
        },
      );

      if (response.success && response.data != null) {
        final result = SyncPushResultModel.fromJson(response.data as Map<String, dynamic>);

        // Mark local invoices as synced
        if (syncedInvoiceIds.isNotEmpty) {
          for (final id in syncedInvoiceIds) {
            await db.update(
              DatabaseTables.localInvoice,
              {"SyncStatus": 1},
              where: "InvoiceId = ?",
              whereArgs: [id],
            );
          }
          await db.update(
            DatabaseTables.localSyncOutbox,
            {"SyncStatus": 3},
            where: "EntityType = 'INVOICE' AND SyncStatus = 1",
          );
        }

        return ApiResponse<SyncPushResultModel>(
          success: true,
          message: response.message,
          data: result,
        );
      }
      return ApiResponse<SyncPushResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<SyncPushResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<int>> pullCatalog({
    required String deviceId,
    DateTime? lastSyncUtc,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.syncPull,
        data: {
          "deviceId": deviceId,
          if (lastSyncUtc != null) "lastSyncTimestampUtc": lastSyncUtc.toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final totalRecords = (data["totalRecords"] as num?)?.toInt() ?? 0;
        final serverTime = DateTime.tryParse(data["serverSyncTimestampUtc"]?.toString() ?? "") ?? DateTime.now().toUtc();

        // Persist categories, products, taxes into local SQLite
        await _applyPulledDataLocally(data, serverTime, deviceId);

        return ApiResponse<int>(
          success: true,
          message: "Catalog pulled and cached successfully.",
          data: totalRecords,
        );
      }
      return ApiResponse<int>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<int>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<SyncAuditLogModel>>> getSyncHistory({String? deviceId, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.syncHistory,
        queryParameters: {
          if (deviceId != null) "deviceId": deviceId,
          "limit": limit,
        },
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => SyncAuditLogModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<SyncAuditLogModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<SyncAuditLogModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<SyncAuditLogModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<int> getPendingOutboxCount() async {
    try {
      final db = await _db.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM ${DatabaseTables.localInvoice} WHERE SyncStatus = 0 AND InvoiceStatus != 3",
      ));
      final outboxPending = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM ${DatabaseTables.localSyncOutbox} WHERE SyncStatus = 1",
      )) ?? 0;
      return (count ?? 0) + outboxPending;
    } catch (_) {
      return 0;
    }
  }

  /// Complete Outbox synchronization for all offline-created entities
  Future<int> syncAllPendingOutbox({required String deviceId, String appVersion = "1.0.0"}) async {
    int totalSynced = 0;
    try {
      final db = await _db.database;

      // 1. Process pending CATEGORIES in outbox
      final pendingCats = await db.query(
        DatabaseTables.localSyncOutbox,
        where: "EntityType = 'CATEGORY' AND SyncStatus = 1",
      );

      for (final catRow in pendingCats) {
        try {
          final payload = jsonDecode(catRow["PayloadJson"] as String) as Map<String, dynamic>;
          final res = await _dioClient.post(ApiEndpoints.categories, data: payload);
          if (res.success && res.data != null) {
            final serverId = (res.data["categoryId"] ?? res.data["id"] as num).toInt();
            final clientGuid = catRow["EntityGuid"] as String;

            final localRow = await db.query(
              DatabaseTables.localCategory,
              where: "CategoryGuid = ?",
              whereArgs: [clientGuid],
            );
            if (localRow.isNotEmpty) {
              final oldId = localRow.first["CategoryId"] as int;
              if (oldId != serverId) {
                await db.update(DatabaseTables.localProduct, {"CategoryId": serverId}, where: "CategoryId = ?", whereArgs: [oldId]);
                await db.delete(DatabaseTables.localCategory, where: "CategoryId = ?", whereArgs: [oldId]);
              }
            }
            await db.insert(
              DatabaseTables.localCategory,
              {
                "CategoryId": serverId,
                "CategoryGuid": clientGuid,
                "CategoryName": payload["categoryName"],
                "Description": payload["description"],
                "DisplayOrder": payload["displayOrder"] ?? 0,
                "IsActive": 1,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            await db.update(DatabaseTables.localSyncOutbox, {"SyncStatus": 3}, where: "OutboxId = ?", whereArgs: [catRow["OutboxId"]]);
            totalSynced++;
          }
        } catch (_) {}
      }

      // 2. Process pending PRODUCTS in outbox
      final pendingProds = await db.query(
        DatabaseTables.localSyncOutbox,
        where: "EntityType = 'PRODUCT' AND SyncStatus = 1",
      );

      for (final prodRow in pendingProds) {
        try {
          final payload = jsonDecode(prodRow["PayloadJson"] as String) as Map<String, dynamic>;
          final res = await _dioClient.post(ApiEndpoints.products, data: payload);
          if (res.success && res.data != null) {
            final serverId = (res.data["productId"] ?? res.data["id"] as num).toInt();
            final clientGuid = prodRow["EntityGuid"] as String;
            await db.update(DatabaseTables.localProduct, {"ProductId": serverId}, where: "ProductGuid = ?", whereArgs: [clientGuid]);
            await db.update(DatabaseTables.localSyncOutbox, {"SyncStatus": 3}, where: "OutboxId = ?", whereArgs: [prodRow["OutboxId"]]);
            totalSynced++;
          }
        } catch (_) {}
      }

      // 3. Process pending INVOICES & CUSTOMERS via pushBatch
      final pushRes = await pushBatch(deviceId: deviceId, appVersion: appVersion);
      if (pushRes.success && pushRes.data != null) {
        totalSynced += pushRes.data!.totalProcessed;
      }
    } catch (_) {}
    return totalSynced;
  }

  Future<void> _saveLocalDeviceState(DeviceStatusModel device) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localDeviceState,
        {
          "DeviceId": device.deviceId,
          "DeviceName": device.deviceName,
          "LastSyncTimeUTC": device.lastSyncTimeUtc?.toIso8601String(),
          "AppVersion": device.appVersion,
          "IsOnline": device.isOnline ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> _applyPulledDataLocally(Map<String, dynamic> data, DateTime serverTime, String deviceId) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        // Categories
        final categories = data["categories"] as List<dynamic>?;
        if (categories != null) {
          for (final c in categories) {
            await txn.insert(
              DatabaseTables.localCategory,
              {
                "CategoryId": c["categoryId"] ?? c["id"],
                "CategoryGuid": c["categoryGuid"],
                "CategoryName": c["categoryName"],
                "Description": c["description"],
                "CategoryImageStorageKey": c["categoryImageStorageKey"],
                "DisplayOrder": c["displayOrder"] ?? 0,
                "IsActive": (c["isActive"] == true) ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Products
        final products = data["products"] as List<dynamic>?;
        if (products != null) {
          for (final p in products) {
            await txn.insert(
              DatabaseTables.localProduct,
              {
                "ProductId": p["productId"] ?? p["id"],
                "ProductGuid": p["productGuid"],
                "CategoryId": p["categoryId"],
                "ProductName": p["productName"],
                "Description": p["description"],
                "ProductImageStorageKey": p["productImageStorageKey"],
                "SellingPrice": (p["sellingPrice"] as num?)?.toDouble() ?? 0.0,
                "TaxId": p["taxId"],
                "TaxPercentage": (p["taxPercentage"] as num?)?.toDouble() ?? 0.0,
                "HSNCode": p["hsnCode"],
                "IsAvailable": (p["isAvailable"] == true) ? 1 : 0,
                "IsActive": (p["isActive"] == true) ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Taxes
        final taxes = data["taxes"] as List<dynamic>?;
        if (taxes != null) {
          for (final t in taxes) {
            await txn.insert(
              DatabaseTables.localTax,
              {
                "TaxId": t["id"],
                "TaxName": t["taxName"],
                "RatePercentage": (t["ratePercentage"] as num?)?.toDouble() ?? 0.0,
                "CgstPercentage": (t["cgstPercentage"] as num?)?.toDouble() ?? 0.0,
                "SgstPercentage": (t["sgstPercentage"] as num?)?.toDouble() ?? 0.0,
                "IgstPercentage": (t["igstPercentage"] as num?)?.toDouble() ?? 0.0,
                "IsActive": (t["isActive"] == true) ? 1 : 0,
                "IsDefault": (t["isDefault"] == true) ? 1 : 0,
                "IsTaxInclusiveDefault": (t["isTaxInclusiveDefault"] == true) ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Update device watermark
        await txn.rawUpdate(
          "UPDATE ${DatabaseTables.localDeviceState} SET LastSyncTimeUTC = ? WHERE DeviceId = ?",
          [serverTime.toIso8601String(), deviceId],
        );
      });
    } catch (_) {}
  }
}

