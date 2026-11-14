import "package:sqflite/sqflite.dart";
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

  Future<BillingInvoiceModel> createInvoice({
    int? customerId,
    String? deviceId,
    required List<CartItemModel> items,
    double discountAmount = 0.0,
    double paidAmount = 0.0,
    int paymentMode = 1,
    String? transactionReference,
  }) async {
    final payload = {
      "customerId": customerId,
      "deviceId": deviceId ?? "POS-TERMINAL-01",
      "items": items.map((i) => i.toJson()).toList(),
      "discountAmount": discountAmount,
      "paidAmount": paidAmount,
      "paymentMode": paymentMode,
      "transactionReference": transactionReference,
    };

    try {
      final response = await _dioClient.post(
        ApiEndpoints.billingCreate,
        data: payload,
      );

      if (response.success && response.data != null) {
        final invoice = BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheInvoiceLocally(invoice);
        return invoice;
      }
    } catch (_) {
      // Offline fallback: create local offline invoice in SQLite
    }

    return await _createOfflineInvoice(
      customerId: customerId,
      deviceId: deviceId,
      items: items,
      discountAmount: discountAmount,
      paidAmount: paidAmount,
      paymentMode: paymentMode,
    );
  }

  Future<BillingInvoiceModel> holdBill({
    int? customerId,
    String? deviceId,
    String? note,
    required List<CartItemModel> items,
    double discountAmount = 0.0,
  }) async {
    final payload = {
      "customerId": customerId,
      "deviceId": deviceId ?? "POS-TERMINAL-01",
      "note": note,
      "items": items.map((i) => i.toJson()).toList(),
      "discountAmount": discountAmount,
    };

    try {
      final response = await _dioClient.post(
        ApiEndpoints.holdBill,
        data: payload,
      );

      if (response.success && response.data != null) {
        final invoice = BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheInvoiceLocally(invoice);
        return invoice;
      }
    } catch (_) {
      // Offline fallback
    }

    return await _createOfflineInvoice(
      customerId: customerId,
      deviceId: deviceId,
      items: items,
      discountAmount: discountAmount,
      paidAmount: 0.0,
      paymentMode: 1,
      isHeld: true,
    );
  }

  Future<List<BillingInvoiceModel>> getHeldBills() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.heldBills);
      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final items = list.map((e) => BillingInvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
        for (final inv in items) {
          await _cacheInvoiceLocally(inv);
        }
        return items;
      }
    } catch (_) {
      // Offline fallback
    }

    final db = await _db.database;
    final rows = await db.query(
      DatabaseTables.localInvoice,
      where: "InvoiceStatus = 3",
      orderBy: "CreatedAtUTC DESC",
    );

    final result = <BillingInvoiceModel>[];
    for (final row in rows) {
      final invId = (row["InvoiceId"] as num).toInt();
      final itemRows = await db.query(
        DatabaseTables.localInvoiceDetail,
        where: "InvoiceId = ?",
        whereArgs: [invId],
      );
      final items = itemRows.map((r) => BillingInvoiceItemModel.fromLocalDbMap(r)).toList();
      result.add(BillingInvoiceModel.fromLocalDbMap(row, items: items));
    }

    return result;
  }

  Future<BillingInvoiceModel> resumeBill(int invoiceId) async {
    try {
      final response = await _dioClient.post("${ApiEndpoints.resumeBill}/$invoiceId");
      if (response.success && response.data != null) {
        return BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Offline fallback
    }

    final inv = await getInvoiceById(invoiceId);
    if (inv != null) return inv;
    throw Exception("Held bill not found");
  }

  Future<bool> cancelBill(int invoiceId, String reason) async {
    try {
      final response = await _dioClient.post(
        "${ApiEndpoints.cancelBill}/$invoiceId",
        data: {"reason": reason},
      );
      if (response.success) {
        final db = await _db.database;
        await db.update(
          DatabaseTables.localInvoice,
          {"InvoiceStatus": 4},
          where: "InvoiceId = ?",
          whereArgs: [invoiceId],
        );
        return true;
      }
    } catch (_) {
      // Offline
    }

    final db = await _db.database;
    await db.update(
      DatabaseTables.localInvoice,
      {"InvoiceStatus": 4},
      where: "InvoiceId = ?",
      whereArgs: [invoiceId],
    );
    return true;
  }

  Future<BillingInvoiceModel?> getInvoiceById(int invoiceId) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.invoices}/$invoiceId");
      if (response.success && response.data != null) {
        final inv = BillingInvoiceModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheInvoiceLocally(inv);
        return inv;
      }
    } catch (_) {
      // Offline fallback
    }

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
    bool isHeld = false,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc();
    final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localInvoice}")) ?? 0;
    final prefix = isHeld ? "HOLD" : "INV";
    final invoiceNumber = "$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}";

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
      final payMap = {
        "InvoiceId": invoiceId,
        "PaymentMode": paymentMode,
        "PaymentModeName": paymentMode == 2 ? "UPI" : (paymentMode == 3 ? "Card" : "Cash"),
        "Amount": paidAmount,
        "PaymentStatus": 2,
        "CreatedAtUTC": now.toIso8601String(),
      };
      final payId = await db.insert(DatabaseTables.localPayment, payMap);
      payments.add(BillingPaymentModel(
        paymentId: payId,
        paymentGuid: "local-${DateTime.now().millisecondsSinceEpoch}",
        invoiceId: invoiceId,
        paymentMode: paymentMode,
        paymentModeName: paymentMode == 2 ? "UPI" : (paymentMode == 3 ? "Card" : "Cash"),
        amount: paidAmount,
        paymentStatus: 2,
        createdAtUtc: now,
      ));
    }

    return BillingInvoiceModel(
      invoiceId: invoiceId,
      invoiceGuid: "local-guid-$invoiceId",
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
