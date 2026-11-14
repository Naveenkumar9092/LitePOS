import "package:sqflite/sqflite.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "../models/payment_models.dart";

class PaymentRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  PaymentRepository(this._dioClient, this._db);

  /// Process single payment
  Future<ApiResponse<PaymentTransactionModel>> processPayment(ProcessPaymentRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.payments,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final payment = PaymentTransactionModel.fromJson(response.data as Map<String, dynamic>);
        await _cachePaymentLocally(payment);
        return ApiResponse<PaymentTransactionModel>(
          success: true,
          message: response.message,
          data: payment,
        );
      }
      return ApiResponse<PaymentTransactionModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      // Offline fallback
      return await _createOfflinePayment(request);
    }
  }

  /// Process split payment
  Future<ApiResponse<List<PaymentTransactionModel>>> processSplitPayment(ProcessSplitPaymentRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.splitPayment,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final p in list) {
          await _cachePaymentLocally(p);
        }
        return ApiResponse<List<PaymentTransactionModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<PaymentTransactionModel>>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      // Offline fallback
      return await _createOfflineSplitPayment(request);
    }
  }

  /// Process refund
  Future<ApiResponse<PaymentTransactionModel>> processRefund(ProcessRefundRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.refundPayment,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final payment = PaymentTransactionModel.fromJson(response.data as Map<String, dynamic>);
        await _cachePaymentLocally(payment);
        return ApiResponse<PaymentTransactionModel>(
          success: true,
          message: response.message,
          data: payment,
        );
      }
      return ApiResponse<PaymentTransactionModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<PaymentTransactionModel>(
        success: false,
        message: "Failed to process refund: $e",
      );
    }
  }

  /// Get payments list
  Future<ApiResponse<PagedPaymentsResponse>> getPayments({
    int? invoiceId,
    PaymentModeEnum? mode,
    PaymentStatusEnum? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        "page": page,
        "pageSize": pageSize,
      };
      if (invoiceId != null) queryParams["invoiceId"] = invoiceId;
      if (mode != null) queryParams["paymentMode"] = mode.value;
      if (status != null) queryParams["paymentStatus"] = status.value;
      if (search != null && search.trim().isNotEmpty) queryParams["search"] = search.trim();

      final response = await _dioClient.get(
        ApiEndpoints.payments,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final pagedResult = PagedPaymentsResponse.fromJson(response.data as Map<String, dynamic>);
        for (final p in pagedResult.items) {
          await _cachePaymentLocally(p);
        }
        return ApiResponse<PagedPaymentsResponse>(
          success: true,
          message: response.message,
          data: pagedResult,
        );
      }
    } catch (_) {
      // Offline fallback
    }

    return await _getOfflinePayments(invoiceId: invoiceId, mode: mode, search: search, page: page, pageSize: pageSize);
  }

  /// Get single payment by ID
  Future<ApiResponse<PaymentTransactionModel>> getPaymentById(int id) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.payments}/$id");
      if (response.success && response.data != null) {
        final payment = PaymentTransactionModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PaymentTransactionModel>(
          success: true,
          message: response.message,
          data: payment,
        );
      }
    } catch (_) {}

    return ApiResponse<PaymentTransactionModel>(
      success: false,
      message: "Payment not found.",
    );
  }

  /// Get payment reconciliation
  Future<ApiResponse<PaymentReconciliationModel>> getReconciliation({DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams["date"] = date.toIso8601String();

      final response = await _dioClient.get(
        ApiEndpoints.paymentReconciliation,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final recon = PaymentReconciliationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PaymentReconciliationModel>(
          success: true,
          message: response.message,
          data: recon,
        );
      }
    } catch (_) {
      // Offline fallback
    }

    return await _getOfflineReconciliation(date ?? DateTime.now());
  }

  /// Open cash register
  Future<ApiResponse<CashRegisterSessionModel>> openCashRegister(OpenRegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.cashRegisterOpen,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final session = CashRegisterSessionModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CashRegisterSessionModel>(
          success: true,
          message: response.message,
          data: session,
        );
      }
      return ApiResponse<CashRegisterSessionModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      // Offline local session open
      return ApiResponse<CashRegisterSessionModel>(
        success: true,
        message: "Register opened locally.",
        data: CashRegisterSessionModel(
          id: 1,
          sessionGuid: "${DateTime.now().millisecondsSinceEpoch}",
          cashierUsername: "Cashier",
          deviceId: "POS-TERMINAL-01",
          openingFloat: request.openingFloat,
          openingTime: DateTime.now(),
          openingNotes: request.notes,
          isOpen: true,
        ),
      );
    }
  }

  /// Close cash register
  Future<ApiResponse<CashRegisterSessionModel>> closeCashRegister(CloseRegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.cashRegisterClose,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final session = CashRegisterSessionModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CashRegisterSessionModel>(
          success: true,
          message: response.message,
          data: session,
        );
      }
      return ApiResponse<CashRegisterSessionModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<CashRegisterSessionModel>(
        success: true,
        message: "Register closed locally.",
        data: CashRegisterSessionModel(
          id: 1,
          sessionGuid: "local-close",
          cashierUsername: "Cashier",
          deviceId: "POS-TERMINAL-01",
          openingFloat: 1000.0,
          openingTime: DateTime.now(),
          closingTime: DateTime.now(),
          actualCash: request.actualCash,
          expectedCash: request.actualCash,
          discrepancy: 0.0,
          closingNotes: request.notes,
          isOpen: false,
        ),
      );
    }
  }

  // --- SQLite Offline Persistence ---

  Future<void> _cachePaymentLocally(PaymentTransactionModel payment) async {
    try {
      final db = await _db.database;
      final map = {
        "PaymentId": payment.id,
        "PaymentGuid": payment.paymentGuid,
        "InvoiceId": payment.invoiceId,
        "PaymentModeId": payment.paymentMode.value,
        "PaymentModeName": payment.paymentModeName,
        "Amount": payment.amount,
        "TransactionReference": payment.transactionReference,
        "PaymentStatus": payment.paymentStatus.value,
        "CreatedAtUTC": payment.createdAt.toUtc().toIso8601String(),
      };

      await db.insert(
        DatabaseTables.localPayment,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<ApiResponse<PagedPaymentsResponse>> _getOfflinePayments({
    int? invoiceId,
    PaymentModeEnum? mode,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final db = await _db.database;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (invoiceId != null) {
        whereClauses.add("InvoiceId = ?");
        whereArgs.add(invoiceId);
      }
      if (mode != null) {
        whereClauses.add("PaymentModeId = ?");
        whereArgs.add(mode.value);
      }

      final whereString = whereClauses.isNotEmpty ? whereClauses.join(" AND ") : null;

      final countResult = await db.rawQuery(
        "SELECT COUNT(*) FROM ${DatabaseTables.localPayment}${whereString != null ? ' WHERE $whereString' : ''}",
        whereArgs,
      );
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      final offset = (page - 1) * pageSize;
      final rows = await db.query(
        DatabaseTables.localPayment,
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: "CreatedAtUTC DESC",
        limit: pageSize,
        offset: offset,
      );

      final items = rows.map((r) => PaymentTransactionModel(
        id: r["PaymentId"] as int,
        paymentGuid: r["PaymentGuid"] as String? ?? "",
        invoiceId: r["InvoiceId"] as int,
        invoiceNumber: "INV-OFFLINE-${r['InvoiceId']}",
        paymentMode: PaymentModeEnum.fromValue(r["PaymentModeId"]),
        paymentModeName: r["PaymentModeName"] as String? ?? "Cash",
        amount: (r["Amount"] as num?)?.toDouble() ?? 0.0,
        transactionReference: r["TransactionReference"] as String?,
        paymentStatus: PaymentStatusEnum.fromValue(r["PaymentStatus"]),
        createdAt: DateTime.tryParse(r["CreatedAtUTC"] as String? ?? "") ?? DateTime.now(),
      )).toList();

      final totalPages = pageSize > 0 ? (totalCount / pageSize).ceil() : 0;
      return ApiResponse<PagedPaymentsResponse>(
        success: true,
        message: "Offline payments loaded.",
        data: PagedPaymentsResponse(
          items: items,
          totalCount: totalCount,
          pageNumber: page,
          pageSize: pageSize,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      return ApiResponse<PagedPaymentsResponse>(
        success: false,
        message: "Failed to load offline payments: $e",
      );
    }
  }

  Future<ApiResponse<PaymentTransactionModel>> _createOfflinePayment(ProcessPaymentRequest request) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toUtc();
      final map = {
        "PaymentGuid": "${now.millisecondsSinceEpoch}",
        "InvoiceId": request.invoiceId,
        "PaymentModeId": request.paymentMode.value,
        "PaymentModeName": request.paymentMode.label,
        "Amount": request.amount,
        "TransactionReference": request.transactionReference,
        "PaymentStatus": PaymentStatusEnum.paid.value,
        "CreatedAtUTC": now.toIso8601String(),
      };

      final id = await db.insert(DatabaseTables.localPayment, map);
      final payment = PaymentTransactionModel(
        id: id,
        paymentGuid: map["PaymentGuid"] as String,
        invoiceId: request.invoiceId,
        invoiceNumber: "INV-OFFLINE-${request.invoiceId}",
        paymentMode: request.paymentMode,
        paymentModeName: request.paymentMode.label,
        amount: request.amount,
        transactionReference: request.transactionReference,
        paymentStatus: PaymentStatusEnum.paid,
        createdAt: now,
      );

      return ApiResponse<PaymentTransactionModel>(
        success: true,
        message: "Payment recorded offline.",
        data: payment,
      );
    } catch (e) {
      return ApiResponse<PaymentTransactionModel>(
        success: false,
        message: "Failed to create offline payment: $e",
      );
    }
  }

  Future<ApiResponse<List<PaymentTransactionModel>>> _createOfflineSplitPayment(ProcessSplitPaymentRequest request) async {
    try {
      final created = <PaymentTransactionModel>[];
      for (final p in request.payments) {
        final subRes = await _createOfflinePayment(ProcessPaymentRequest(
          invoiceId: request.invoiceId,
          paymentMode: p.paymentMode,
          amount: p.amount,
          transactionReference: p.transactionReference,
        ));
        if (subRes.success && subRes.data != null) {
          created.add(subRes.data!);
        }
      }
      return ApiResponse<List<PaymentTransactionModel>>(
        success: true,
        message: "Split payments recorded offline.",
        data: created,
      );
    } catch (e) {
      return ApiResponse<List<PaymentTransactionModel>>(
        success: false,
        message: "Failed to record split payments offline: $e",
      );
    }
  }

  Future<ApiResponse<PaymentReconciliationModel>> _getOfflineReconciliation(DateTime date) async {
    try {
      final db = await _db.database;
      final rows = await db.query(DatabaseTables.localPayment);

      double cash = 0.0;
      double upi = 0.0;
      double card = 0.0;
      double refunds = 0.0;

      for (final r in rows) {
        final mode = r["PaymentModeId"] as int;
        final amount = (r["Amount"] as num?)?.toDouble() ?? 0.0;
        if (amount < 0) {
          refunds += amount.abs();
        } else if (mode == 1) {
          cash += amount;
        } else if (mode == 2) {
          upi += amount;
        } else if (mode == 3) {
          card += amount;
        }
      }

      final net = cash + upi + card - refunds;
      return ApiResponse<PaymentReconciliationModel>(
        success: true,
        message: "Offline reconciliation loaded.",
        data: PaymentReconciliationModel(
          date: date,
          openingFloat: 1000.0,
          cashCollected: cash,
          upiCollected: upi,
          cardCollected: card,
          totalRefunds: refunds,
          netCollected: net,
          totalTransactions: rows.length,
          expectedCashInDrawer: 1000.0 + cash - refunds,
          isRegisterOpen: true,
        ),
      );
    } catch (e) {
      return ApiResponse<PaymentReconciliationModel>(
        success: false,
        message: "Failed to load offline reconciliation: $e",
      );
    }
  }
}
