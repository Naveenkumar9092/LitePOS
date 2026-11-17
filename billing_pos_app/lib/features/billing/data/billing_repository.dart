import "dart:async";
import "dart:convert";
import "package:sqflite/sqflite.dart";
import "package:uuid/uuid.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "../models/billing_invoice_model.dart";
import "../models/cart_item_model.dart";

class BillingRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  BillingRepository(this._dioClient, this._db);

  /// Offline-First: Stores in Local SQLite first (< 5ms), returns immediately to UI,
  /// then triggers background cloud sync asynchronously without slowing down checkout.
  Future<BillingInvoiceModel> createInvoice({
    int? customerId,
    String? deviceId,
    required List<CartItemModel> items,
    double discountAmount = 0.0,
    double paidAmount = 0.0,
    int paymentMode = 1,
    String? transactionReference,
  }) async {
    // 1. Instantly write to Local DB (0 UI wait time, POS is blazing fast)
    final localInvoice = await _createOfflineInvoice(
      customerId: customerId,
      deviceId: deviceId,
      items: items,
      discountAmount: discountAmount,
      paidAmount: paidAmount,
      paymentMode: paymentMode,
      transactionReference: transactionReference,
    );

    // 2. Dispatch non-blocking background sync when online
    unawaited(_syncInvoiceInBackground(localInvoice));

    return localInvoice;
  }

  /// Non-blocking background sync for a single generated bill
  Future<void> _syncInvoiceInBackground(BillingInvoiceModel invoice) async {
    try {
      final db = await _db.database;
      final itemRows = await db.query(
        DatabaseTables.localInvoiceDetail,
        where: "InvoiceId = ?",
        whereArgs: [invoice.invoiceId],
      );
      final paymentRows = await db.query(
        DatabaseTables.localPayment,
        where: "InvoiceId = ?",
        whereArgs: [invoice.invoiceId],
      );

      final items = itemRows.map((it) => {
        "productId": it["ProductId"],
        "productNameSnapshot": it["ProductNameSnapshot"],
        "unitPrice": it["UnitPrice"],
        "quantity": (it["Quantity"] as num).toInt(),
        "discountAmount": it["DiscountAmount"],
        "taxPercentage": it["TaxPercentage"],
        "taxAmount": it["TaxAmount"],
        "lineTotal": it["LineTotal"],
      }).toList();

      final payments = paymentRows.map((p) => {
        "paymentGuid": p["PaymentGuid"]?.toString() ?? const Uuid().v4(),
        "paymentMode": p["PaymentModeId"] ?? 1,
        "amount": p["Amount"],
        "transactionReference": p["TransactionReference"],
        "paymentStatus": p["PaymentStatus"] ?? 2,
        "createdAtUtc": p["CreatedAtUTC"] ?? DateTime.now().toUtc().toIso8601String(),
      }).toList();

      final invoicePayload = {
        "invoiceGuid": invoice.invoiceGuid,
        "invoiceNumber": invoice.invoiceNumber,
        "customerId": invoice.customerId,
        "customerGuid": null,
        "cashierId": invoice.cashierId,
        "invoiceDateUtc": invoice.invoiceDateUtc.toIso8601String(),
        "subTotal": invoice.subTotal,
        "discountAmount": invoice.discountAmount,
        "taxableAmount": invoice.taxableAmount,
        "taxAmount": invoice.taxAmount,
        "grandTotal": invoice.grandTotal,
        "paidAmount": invoice.paidAmount,
        "balanceAmount": invoice.balanceAmount,
        "paymentStatus": invoice.paymentStatus,
        "invoiceStatus": invoice.invoiceStatus,
        "items": items,
        "payments": payments,
      };

      final response = await _dioClient.post(
        ApiEndpoints.syncPush,
        data: {
          "deviceId": invoice.deviceId,
          "appVersion": "1.0.0",
          "clientSyncTimestampUtc": DateTime.now().toUtc().toIso8601String(),
          "customers": [],
          "invoices": [invoicePayload],
        },
      );

      if (response.success) {
        await db.update(
          DatabaseTables.localInvoice,
          {"SyncStatus": 1},
          where: "InvoiceId = ?",
          whereArgs: [invoice.invoiceId],
        );
        await db.update(
          DatabaseTables.localSyncOutbox,
          {"SyncStatus": 3},
          where: "EntityGuid = ?",
          whereArgs: [invoice.invoiceGuid],
        );
      }
    } catch (_) {
      // Offline or network error: record stays in local DB with SyncStatus=0
      // Next sync cycle will automatically upload it when internet is available.
    }
  }

  /// Batch sync all pending local invoices to cloud
  Future<int> syncPendingInvoices() async {
    try {
      final db = await _db.database;
      final unsynced = await db.query(
        DatabaseTables.localInvoice,
        where: "SyncStatus = 0 AND InvoiceStatus != 3",
      );

      if (unsynced.isEmpty) return 0;

      final invoicesToPush = <Map<String, dynamic>>[];
      final invoiceIds = <int>[];
      final invoiceGuids = <String>[];

      for (final row in unsynced) {
        final invId = (row["InvoiceId"] as num).toInt();
        final invGuid = row["InvoiceGuid"]?.toString() ?? const Uuid().v4();
        invoiceIds.add(invId);
        invoiceGuids.add(invGuid);

        final itemRows = await db.query(
          DatabaseTables.localInvoiceDetail,
          where: "InvoiceId = ?",
          whereArgs: [invId],
        );
        final paymentRows = await db.query(
          DatabaseTables.localPayment,
          where: "InvoiceId = ?",
          whereArgs: [invId],
        );

        final items = itemRows.map((it) => {
          "productId": it["ProductId"],
          "productNameSnapshot": it["ProductNameSnapshot"],
          "unitPrice": it["UnitPrice"],
          "quantity": (it["Quantity"] as num).toInt(),
          "discountAmount": it["DiscountAmount"],
          "taxPercentage": it["TaxPercentage"],
          "taxAmount": it["TaxAmount"],
          "lineTotal": it["LineTotal"],
        }).toList();

        final payments = paymentRows.map((p) => {
          "paymentGuid": p["PaymentGuid"]?.toString() ?? const Uuid().v4(),
          "paymentMode": p["PaymentModeId"] ?? 1,
          "amount": p["Amount"],
          "transactionReference": p["TransactionReference"],
          "paymentStatus": p["PaymentStatus"] ?? 2,
          "createdAtUtc": p["CreatedAtUTC"] ?? DateTime.now().toUtc().toIso8601String(),
        }).toList();

        invoicesToPush.add({
          "invoiceGuid": invGuid,
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
          "items": items,
          "payments": payments,
        });
      }

      final response = await _dioClient.post(
        ApiEndpoints.syncPush,
        data: {
          "deviceId": "POS-TERMINAL-01",
          "appVersion": "1.0.0",
          "clientSyncTimestampUtc": DateTime.now().toUtc().toIso8601String(),
          "customers": [],
          "invoices": invoicesToPush,
        },
      );

      if (response.success) {
        for (final id in invoiceIds) {
          await db.update(
            DatabaseTables.localInvoice,
            {"SyncStatus": 1},
            where: "InvoiceId = ?",
            whereArgs: [id],
          );
        }
        for (final guid in invoiceGuids) {
          await db.update(
            DatabaseTables.localSyncOutbox,
            {"SyncStatus": 3},
            where: "EntityGuid = ?",
            whereArgs: [guid],
          );
        }
        return invoiceIds.length;
      }
    } catch (_) {}
    return 0;
  }

  Future<BillingInvoiceModel> holdBill({
    int? customerId,
    String? deviceId,
    String? note,
    required List<CartItemModel> items,
    double discountAmount = 0.0,
  }) async {
    // 1. FAST LOCAL-FIRST: Save held invoice in SQLite immediately (< 2ms)
    final heldInvoice = await _createOfflineInvoice(
      customerId: customerId,
      deviceId: deviceId,
      items: items,
      discountAmount: discountAmount,
      paidAmount: 0.0,
      paymentMode: 1,
      isHeld: true,
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        final itemRows = items.map((it) => {
          "productId": it.productId,
          "productNameSnapshot": it.productName,
          "quantity": it.quantity,
          "unitPrice": it.unitPrice,
          "discountAmount": it.discountAmount,
          "taxPercentage": it.taxPercentage,
        }).toList();

        await _dioClient.post(
          ApiEndpoints.holdBill,
          data: {
            "customerId": customerId,
            "note": note,
            "items": itemRows,
          },
        );
      } catch (_) {}
    }());

    return heldInvoice;
  }

  Future<List<BillingInvoiceModel>> getHeldBills() async {
    // 1. FAST LOCAL-FIRST: Read held bills from local SQLite immediately (< 1ms)
    final db = await _db.database;
    final rows = await db.query(
      DatabaseTables.localInvoice,
      where: "InvoiceStatus = 3",
      orderBy: "CreatedAtUTC DESC",
    );

    final localResult = <BillingInvoiceModel>[];
    for (final row in rows) {
      final invId = (row["InvoiceId"] as num).toInt();
      final itemRows = await db.query(
        DatabaseTables.localInvoiceDetail,
        where: "InvoiceId = ?",
        whereArgs: [invId],
      );
      final items = itemRows.map((r) => BillingInvoiceItemModel.fromLocalDbMap(r)).toList();
      localResult.add(BillingInvoiceModel.fromLocalDbMap(row, items: items));
    }

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        final response = await _dioClient.get(ApiEndpoints.heldBills);
        if (response.success && response.data != null) {
          final list = response.data as List<dynamic>;
          final items = list.map((e) => BillingInvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
          for (final inv in items) {
            await _cacheInvoiceLocally(inv);
          }
        }
      } catch (_) {}
    }());

    return localResult;
  }

  Future<BillingInvoiceModel> resumeBill(int invoiceId) async {
    // 1. FAST LOCAL-FIRST: Resume from local DB immediately
    final inv = await getInvoiceById(invoiceId);
    if (inv != null) {
      // 2. Next: notify server in background
      unawaited(() async {
        try {
          await _dioClient.post("${ApiEndpoints.resumeBill}/$invoiceId");
        } catch (_) {}
      }());
      return inv;
    }

    // Fallback if not found locally
    try {
      final response = await _dioClient.post("${ApiEndpoints.resumeBill}/$invoiceId");
      if (response.success && response.data != null) {
        final remoteInv = BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheInvoiceLocally(remoteInv);
        return remoteInv;
      }
    } catch (_) {}

    throw Exception("Held bill not found");
  }

  Future<bool> cancelBill(int invoiceId, String reason) async {
    // 1. FAST LOCAL-FIRST: Cancel in local SQLite immediately
    final db = await _db.database;
    await db.update(
      DatabaseTables.localInvoice,
      {"InvoiceStatus": 4},
      where: "InvoiceId = ?",
      whereArgs: [invoiceId],
    );

    // 2. Next: sync cancellation with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.post(
          "${ApiEndpoints.cancelBill}/$invoiceId",
          data: {"reason": reason},
        );
      } catch (_) {}
    }());

    return true;
  }

  Future<BillingInvoiceModel?> getInvoiceById(int invoiceId) async {
    // 1. FAST LOCAL-FIRST: Load from local SQLite immediately
    final db = await _db.database;
    final rows = await db.query(
      DatabaseTables.localInvoice,
      where: "InvoiceId = ?",
      whereArgs: [invoiceId],
    );

    if (rows.isNotEmpty) {
      final itemRows = await db.query(
        DatabaseTables.localInvoiceDetail,
        where: "InvoiceId = ?",
        whereArgs: [invoiceId],
      );
      final items = itemRows.map((r) => BillingInvoiceItemModel.fromLocalDbMap(r)).toList();

      final payRows = await db.query(
        DatabaseTables.localPayment,
        where: "InvoiceId = ?",
        whereArgs: [invoiceId],
      );
      final payments = payRows.map((r) => BillingPaymentModel.fromLocalDbMap(r)).toList();

      return BillingInvoiceModel.fromLocalDbMap(rows.first, items: items, payments: payments);
    }

    // 2. Fallback to Online DB if not found in local DB
    try {
      final response = await _dioClient.get("${ApiEndpoints.invoices}/$invoiceId");
      if (response.success && response.data != null) {
        final inv = BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheInvoiceLocally(inv);
        return inv;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _cacheInvoiceLocally(BillingInvoiceModel invoice) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localInvoice,
        invoice.toLocalDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final item in invoice.items) {
        await db.insert(
          DatabaseTables.localInvoiceDetail,
          item.toLocalDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final pay in invoice.payments) {
        await db.insert(
          DatabaseTables.localPayment,
          pay.toLocalDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }

  Future<BillingInvoiceModel> _createOfflineInvoice({
    int? customerId,
    String? deviceId,
    required List<CartItemModel> items,
    required double discountAmount,
    required double paidAmount,
    required int paymentMode,
    String? transactionReference,
    bool isHeld = false,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc();
    final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localInvoice}")) ?? 0;
    final prefix = isHeld ? "HOLD" : "INV";
    final invoiceNumber = "$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}";
    final invoiceGuid = const Uuid().v4();

    double subTotal = 0.0;
    double totalTax = 0.0;
    for (final it in items) {
      subTotal += it.subTotal;
      totalTax += it.taxAmount;
    }
    final taxable = (subTotal - discountAmount) > 0 ? (subTotal - discountAmount) : 0.0;
    final grandTotal = taxable + totalTax;
    final balance = (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0.0;

    final invoiceMap = {
      "InvoiceGuid": invoiceGuid,
      "InvoiceNumber": invoiceNumber,
      "CompanyId": 1,
      "ShopId": 1,
      "CustomerId": customerId,
      "CashierId": 1,
      "DeviceId": deviceId ?? "POS-TERMINAL-01",
      "InvoiceDateUTC": now.toIso8601String(),
      "SubTotal": subTotal,
      "DiscountAmount": discountAmount,
      "TaxableAmount": taxable,
      "TaxAmount": totalTax,
      "GrandTotal": grandTotal,
      "PaidAmount": paidAmount,
      "BalanceAmount": balance,
      "PaymentStatus": paidAmount >= grandTotal ? 2 : (paidAmount > 0 ? 3 : 1),
      "InvoiceStatus": isHeld ? 3 : 2,
      "SyncStatus": 0, // Unsynced
      "CreatedAtUTC": now.toIso8601String(),
    };

    final invoiceId = await db.insert(DatabaseTables.localInvoice, invoiceMap);

    final invoiceItems = <BillingInvoiceItemModel>[];
    for (final it in items) {
      final itemMap = {
        "InvoiceId": invoiceId,
        "ProductId": it.productId,
        "ProductNameSnapshot": it.productName,
        "UnitPrice": it.unitPrice,
        "Quantity": it.quantity,
        "DiscountAmount": it.discountAmount,
        "TaxPercentage": it.taxPercentage,
        "TaxAmount": it.taxAmount,
        "LineTotal": it.lineTotal,
      };
      final detailId = await db.insert(DatabaseTables.localInvoiceDetail, itemMap);
      invoiceItems.add(BillingInvoiceItemModel(
        invoiceDetailId: detailId,
        invoiceId: invoiceId,
        productId: it.productId,
        productNameSnapshot: it.productName,
        unitPrice: it.unitPrice,
        quantity: it.quantity,
        discountAmount: it.discountAmount,
        taxPercentage: it.taxPercentage,
        taxAmount: it.taxAmount,
        lineTotal: it.lineTotal,
      ));
    }

    final payments = <BillingPaymentModel>[];
    if (paidAmount > 0 && !isHeld) {
      final paymentGuid = const Uuid().v4();
      final payMap = {
        "PaymentGuid": paymentGuid,
        "InvoiceId": invoiceId,
        "PaymentModeId": paymentMode,
        "PaymentModeName": paymentMode == 2 ? "UPI" : (paymentMode == 3 ? "Card" : "Cash"),
        "Amount": paidAmount,
        "TransactionReference": transactionReference,
        "PaymentStatus": 2,
        "CreatedAtUTC": now.toIso8601String(),
      };
      final payId = await db.insert(DatabaseTables.localPayment, payMap);
      payments.add(BillingPaymentModel(
        paymentId: payId,
        paymentGuid: paymentGuid,
        invoiceId: invoiceId,
        paymentMode: paymentMode,
        paymentModeName: paymentMode == 2 ? "UPI" : (paymentMode == 3 ? "Card" : "Cash"),
        amount: paidAmount,
        paymentStatus: 2,
        createdAtUtc: now,
      ));
    }

    // Queue into local sync outbox for background push
    if (!isHeld) {
      try {
        await db.insert(
          DatabaseTables.localSyncOutbox,
          {
            "EventGuid": const Uuid().v4(),
            "IdempotencyKey": invoiceGuid,
            "EntityType": "INVOICE",
            "EntityGuid": invoiceGuid,
            "PayloadJson": jsonEncode(invoiceMap),
            "SyncStatus": 1, // Pending
            "RetryCount": 0,
            "CreatedAtUTC": now.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }

    return BillingInvoiceModel(
      invoiceId: invoiceId,
      invoiceGuid: invoiceGuid,
      invoiceNumber: invoiceNumber,
      companyId: 1,
      companyName: "LitePOS Cafe",
      shopId: 1,
      shopName: "Main Branch",
      customerId: customerId,
      cashierId: 1,
      cashierName: "Cashier",
      deviceId: deviceId ?? "POS-TERMINAL-01",
      invoiceDateUtc: now,
      subTotal: subTotal,
      discountAmount: discountAmount,
      taxableAmount: taxable,
      taxAmount: totalTax,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      balanceAmount: balance,
      paymentStatus: paidAmount >= grandTotal ? 2 : (paidAmount > 0 ? 3 : 1),
      invoiceStatus: isHeld ? 3 : 2,
      syncStatus: 0,
      items: invoiceItems,
      payments: payments,
      createdAtUtc: now,
    );
  }
}
