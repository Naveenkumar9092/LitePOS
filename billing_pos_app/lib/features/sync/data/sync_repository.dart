import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite/sqflite.dart";
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
      final response = await _dioClient.post(
        ApiEndpoints.syncPush,
        data: {
          "deviceId": deviceId,
          "appVersion": appVersion,
          "clientSyncTimestampUtc": DateTime.now().toUtc().toIso8601String(),
          "customers": customers,
          "invoices": invoices,
        },
      );

      if (response.success && response.data != null) {
        final result = SyncPushResultModel.fromJson(response.data as Map<String, dynamic>);
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
        "SELECT COUNT(*) FROM ${DatabaseTables.localSyncOutbox} WHERE SyncStatus = 1",
      ));
      return count ?? 0;
    } catch (_) {
      return 0;
    }
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

