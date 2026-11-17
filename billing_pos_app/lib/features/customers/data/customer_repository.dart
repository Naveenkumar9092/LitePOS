import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite/sqflite.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/customer_model.dart";

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return CustomerRepository(dioClient, db);
});

class CustomerRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  CustomerRepository(this._dioClient, this._db);

  /// Fetch customers with optional search and pagination (LOCAL-FIRST)
  Future<ApiResponse<PagedCustomersResponse>> getCustomers({String? search, int page = 1, int size = 20}) async {
    // 1. FAST LOCAL-FIRST: Load customers from SQLite immediately (< 1ms)
    final localResult = await _loadLocalCustomers(search: search, page: page, size: size);

    // 2. Background sync from server (unblocking UI!)
    unawaited(_syncCustomersInBackground(search: search, page: page, size: size));

    if (localResult.data != null && localResult.data!.items.isNotEmpty) {
      return localResult;
    }

    return await _fetchRemoteCustomers(search: search, page: page, size: size);
  }

  Future<void> _syncCustomersInBackground({String? search, int page = 1, int size = 20}) async {
    try {
      final remote = await _fetchRemoteCustomers(search: search, page: page, size: size);
      if (remote.data != null && remote.data!.items.isNotEmpty) {
        await _cacheCustomersLocally(remote.data!.items);
      }
    } catch (_) {}
  }

  Future<ApiResponse<PagedCustomersResponse>> _fetchRemoteCustomers({String? search, int page = 1, int size = 20}) async {
    try {
      final Map<String, dynamic> params = {
        "pageNumber": page,
        "pageSize": size,
      };
      if (search != null && search.trim().isNotEmpty) {
        params["search"] = search.trim();
      }

      final response = await _dioClient.get(
        ApiEndpoints.customers,
        queryParameters: params,
      );

      if (response.success && response.data != null) {
        final paged = PagedCustomersResponse.fromJson(response.data as Map<String, dynamic>);
        unawaited(_cacheCustomersLocally(paged.items));
        return ApiResponse<PagedCustomersResponse>(
          success: true,
          message: response.message,
          data: paged,
        );
      }
    } catch (_) {}

    return await _loadLocalCustomers(search: search, page: page, size: size);
  }

  /// Lookup customers by mobile number or name for fast POS checkout (LOCAL-FIRST)
  Future<ApiResponse<List<CustomerLookupModel>>> lookupCustomers(String query) async {
    // 1. FAST LOCAL-FIRST: Query local SQLite immediately (< 1ms)
    final localList = await _loadLocalLookupCustomers(query);
    if (localList.isNotEmpty) {
      return ApiResponse<List<CustomerLookupModel>>(
        success: true,
        message: "Loaded from local DB",
        data: localList,
      );
    }

    // 2. Fallback to remote if not found locally
    try {
      final response = await _dioClient.get(
        "${ApiEndpoints.customers}/lookup",
        queryParameters: {"query": query},
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => CustomerLookupModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<CustomerLookupModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
    } catch (_) {}

    return ApiResponse<List<CustomerLookupModel>>(
      success: true,
      message: "No customers found",
      data: [],
    );
  }

  Future<List<CustomerLookupModel>> _loadLocalLookupCustomers(String query) async {
    try {
      final db = await _db.database;
      final q = "%$query%";
      final rows = await db.query(
        DatabaseTables.localCustomer,
        where: "IsActive = 1 AND (MobileNumber LIKE ? OR CustomerName LIKE ?)",
        whereArgs: [q, q],
        limit: 10,
      );

      return rows.map((r) => CustomerLookupModel(
        id: (r["CustomerId"] as num).toInt(),
        customerName: r["CustomerName"]?.toString() ?? "",
        mobileNumber: r["MobileNumber"]?.toString() ?? "",
        gstin: r["GSTIN"]?.toString(),
        email: r["Email"]?.toString(),
        whatsAppNumber: r["WhatsAppNumber"]?.toString(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get Customer by ID
  Future<ApiResponse<CustomerModel>> getCustomerById(int id) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.customers}/$id");
      if (response.success && response.data != null) {
        final customer = CustomerModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheSingleCustomerLocally(customer);
        return ApiResponse<CustomerModel>(
          success: true,
          message: response.message,
          data: customer,
        );
      }
      return ApiResponse<CustomerModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      final db = await _db.database;
      final rows = await db.query(
        DatabaseTables.localCustomer,
        where: "CustomerId = ?",
        whereArgs: [id],
      );
      if (rows.isNotEmpty) {
        return ApiResponse<CustomerModel>(
          success: true,
          message: "Loaded from local database.",
          data: CustomerModel.fromSqlite(rows.first),
        );
      }
      return ApiResponse<CustomerModel>(
        success: false,
        message: "Customer not found locally.",
      );
    }
  }

  /// Create Customer (LOCAL DB FIRST -> NEXT ONLINE DB)
  Future<ApiResponse<CustomerModel>> createCustomer(CreateCustomerRequest request) async {
    // 1. FAST LOCAL-FIRST: Save in SQLite immediately (< 1ms)
    final db = await _db.database;
    final maxIdRow = await db.rawQuery("SELECT MAX(CustomerId) as maxId FROM ${DatabaseTables.localCustomer}");
    final maxId = (maxIdRow.first["maxId"] as num?)?.toInt() ?? 0;
    final localId = maxId > 0 ? maxId + 1 : (DateTime.now().millisecondsSinceEpoch % 100000);

    final localCustomer = CustomerModel(
      id: localId,
      customerGuid: "offline-$localId",
      customerName: request.customerName,
      mobileNumber: request.mobileNumber,
      whatsAppNumber: request.whatsAppNumber ?? request.mobileNumber,
      email: request.email,
      address: request.address,
      gstin: request.gstin,
      emailConsent: request.emailConsent,
      whatsAppConsent: request.whatsAppConsent,
      totalInvoicesCount: 0,
      totalSpent: 0.0,
      lastVisitDateUtc: null,
      isActive: true,
      createdAtUtc: DateTime.now().toUtc(),
    );

    await db.insert(
      DatabaseTables.localCustomer,
      localCustomer.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Next: sync with Online DB in background
    unawaited(_syncCreateCustomerInBackground(localCustomer, request));

    return ApiResponse<CustomerModel>(
      success: true,
      message: "Customer created successfully.",
      data: localCustomer,
    );
  }

  Future<void> _syncCreateCustomerInBackground(CustomerModel localCustomer, CreateCustomerRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.customers,
        data: request.toJson(),
      );
      if (response.success && response.data != null) {
        final serverCustomer = CustomerModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheSingleCustomerLocally(serverCustomer);
      }
    } catch (_) {}
  }

  /// Update Customer (LOCAL DB FIRST -> NEXT ONLINE DB)
  Future<ApiResponse<CustomerModel>> updateCustomer(int id, UpdateCustomerRequest request) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately
    final db = await _db.database;
    final updateMap = <String, dynamic>{
      "CustomerName": request.customerName,
      "MobileNumber": request.mobileNumber,
      if (request.whatsAppNumber != null) "WhatsAppNumber": request.whatsAppNumber,
      if (request.email != null) "Email": request.email,
      if (request.address != null) "Address": request.address,
      if (request.gstin != null) "GSTIN": request.gstin,
      "EmailConsent": request.emailConsent ? 1 : 0,
      "WhatsAppConsent": request.whatsAppConsent ? 1 : 0,
      "IsActive": request.isActive ? 1 : 0,
    };

    await db.update(
      DatabaseTables.localCustomer,
      updateMap,
      where: "CustomerId = ?",
      whereArgs: [id],
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.put(
          "${ApiEndpoints.customers}/$id",
          data: request.toJson(),
        );
      } catch (_) {}
    }());

    final rows = await db.query(DatabaseTables.localCustomer, where: "CustomerId = ?", whereArgs: [id]);
    if (rows.isNotEmpty) {
      return ApiResponse<CustomerModel>(
        success: true,
        message: "Customer updated successfully.",
        data: CustomerModel.fromSqlite(rows.first),
      );
    }

    return ApiResponse<CustomerModel>(
      success: true,
      message: "Customer updated successfully.",
      data: CustomerModel(
        id: id,
        customerGuid: "offline-$id",
        customerName: request.customerName,
        mobileNumber: request.mobileNumber,
        whatsAppNumber: request.whatsAppNumber,
        email: request.email,
        address: request.address,
        gstin: request.gstin,
        emailConsent: request.emailConsent,
        whatsAppConsent: request.whatsAppConsent,
        totalInvoicesCount: 0,
        totalSpent: 0.0,
        lastVisitDateUtc: null,
        isActive: request.isActive,
        createdAtUtc: DateTime.now(),
      ),
    );
  }

  /// Get Purchase History
  Future<ApiResponse<CustomerPurchaseHistoryModel>> getPurchaseHistory(int id) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.customers}/$id/history");
      if (response.success && response.data != null) {
        final history = CustomerPurchaseHistoryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CustomerPurchaseHistoryModel>(
          success: true,
          message: response.message,
          data: history,
        );
      }
      return ApiResponse<CustomerPurchaseHistoryModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<CustomerPurchaseHistoryModel>(
        success: false,
        message: "Failed to load purchase history: $e",
      );
    }
  }

  // --- SQLite Helpers ---

  Future<void> _cacheCustomersLocally(List<CustomerModel> list) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      for (final c in list) {
        batch.insert(
          DatabaseTables.localCustomer,
          c.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> _cacheSingleCustomerLocally(CustomerModel customer) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localCustomer,
        customer.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<ApiResponse<PagedCustomersResponse>> _loadLocalCustomers({String? search, int page = 1, int size = 20}) async {
    try {
      final db = await _db.database;
      String? where;
      List<dynamic>? args;

      if (search != null && search.trim().isNotEmpty) {
        final q = "%${search.trim()}%";
        where = "CustomerName LIKE ? OR MobileNumber LIKE ?";
        args = [q, q];
      }

      final total = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM ${DatabaseTables.localCustomer} ${where != null ? 'WHERE $where' : ''}",
          args,
        ),
      ) ?? 0;

      final rows = await db.query(
        DatabaseTables.localCustomer,
        where: where,
        whereArgs: args,
        limit: size,
        offset: (page - 1) * size,
        orderBy: "CustomerId DESC",
      );

      final list = rows.map(CustomerModel.fromSqlite).toList();
      final totalPages = (total / size).ceil();

      return ApiResponse<PagedCustomersResponse>(
        success: true,
        message: "Offline customers loaded.",
        data: PagedCustomersResponse(
          items: list,
          totalCount: total,
          pageNumber: page,
          pageSize: size,
          totalPages: totalPages < 1 ? 1 : totalPages,
        ),
      );
    } catch (_) {
      return ApiResponse<PagedCustomersResponse>(
        success: true,
        message: "Offline fallback (empty).",
        data: PagedCustomersResponse(
          items: const [],
          totalCount: 0,
          pageNumber: page,
          pageSize: size,
          totalPages: 1,
        ),
      );
    }
  }
}

