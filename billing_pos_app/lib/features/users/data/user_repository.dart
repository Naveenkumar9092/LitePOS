import "dart:async";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/network/dio_client.dart";
import "../../authentication/models/user_model.dart";
import "../models/login_audit_log_model.dart";
import "../models/role_model.dart";

class PagedUsersResult {
  final List<UserModel> items;
  final int totalCount;
  final int pageIndex;
  final int pageSize;

  PagedUsersResult({
    required this.items,
    required this.totalCount,
    required this.pageIndex,
    required this.pageSize,
  });
}

class UserRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  UserRepository(this._dioClient, this._db);

  Future<PagedUsersResult> getUsers({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    int? roleId,
    bool? isActive,
    int? companyId,
    bool excludeCashiers = false,
    bool onlyCashiers = false,
  }) async {
    // 1. FAST LOCAL-FIRST: Load SQLite local users immediately (< 1ms)
    final localItems = await getLocalUsers(
      search: search,
      roleId: roleId,
      isActive: isActive,
      companyId: companyId,
      excludeCashiers: excludeCashiers,
      onlyCashiers: onlyCashiers,
    );

    // 2. Background sync from server (unblocking UI!)
    unawaited(_syncUsersInBackground(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      roleId: roleId,
      isActive: isActive,
      companyId: companyId,
      excludeCashiers: excludeCashiers,
      onlyCashiers: onlyCashiers,
    ));

    if (localItems.isNotEmpty) {
      return PagedUsersResult(
        items: localItems,
        totalCount: localItems.length,
        pageIndex: pageNumber,
        pageSize: pageSize,
      );
    }

    // 3. If local DB was completely empty, await remote
    return await _fetchRemoteUsers(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      roleId: roleId,
      isActive: isActive,
      companyId: companyId,
      excludeCashiers: excludeCashiers,
      onlyCashiers: onlyCashiers,
    );
  }

  Future<void> _syncUsersInBackground({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    int? roleId,
    bool? isActive,
    int? companyId,
    bool excludeCashiers = false,
    bool onlyCashiers = false,
  }) async {
    try {
      if (await _dioClient.isOfflineMode) return;
      final remote = await _fetchRemoteUsers(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: search,
        roleId: roleId,
        isActive: isActive,
        companyId: companyId,
        excludeCashiers: excludeCashiers,
        onlyCashiers: onlyCashiers,
      );
      if (remote.items.isNotEmpty) {
        await _cacheUsersBatch(remote.items);
      }
    } catch (_) {}
  }

  Future<PagedUsersResult> _fetchRemoteUsers({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    int? roleId,
    bool? isActive,
    int? companyId,
    bool excludeCashiers = false,
    bool onlyCashiers = false,
  }) async {
    final queryParams = <String, dynamic>{
      "pageNumber": pageNumber,
      "pageSize": pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams["search"] = search;
    if (roleId != null && roleId > 0) queryParams["roleId"] = roleId;
    if (isActive != null) queryParams["isActive"] = isActive;
    if (companyId != null && companyId > 0) queryParams["companyId"] = companyId;

    try {
      final response = await _dioClient.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rawItems = data["items"] as List<dynamic>? ?? [];
        var items = rawItems.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();

        // Scope enforcement
        if (excludeCashiers) {
          items = items.where((u) => !u.isCashier).toList();
        } else if (onlyCashiers) {
          items = items.where((u) => u.isCashier && (companyId == null || companyId == 0 || u.companyId == companyId)).toList();
        }

        final totalCount = items.length;
        unawaited(_cacheUsersBatch(items));

        return PagedUsersResult(
          items: items,
          totalCount: totalCount,
          pageIndex: pageNumber,
          pageSize: pageSize,
        );
      }
    } catch (_) {}

    final localFallback = await getLocalUsers(
      search: search,
      roleId: roleId,
      isActive: isActive,
      companyId: companyId,
      excludeCashiers: excludeCashiers,
      onlyCashiers: onlyCashiers,
    );
    return PagedUsersResult(
      items: localFallback,
      totalCount: localFallback.length,
      pageIndex: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post<UserModel>(
        ApiEndpoints.users,
        data: data,
        fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await _cacheUser(response.data!);
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      // Local SQLite fallback when offline or cold start
      final roleId = (data["roleId"] as num?)?.toInt() ?? 3;
      final roleName = roleId == 1 ? "SAdmin" : (roleId == 2 ? "Admin" : "Cashier");
      final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final localUser = UserModel(
        id: newId,
        companyId: (data["companyId"] as num?)?.toInt() ?? 1,
        fullName: data["fullName"]?.toString() ?? "",
        username: data["username"]?.toString() ?? "",
        email: data["email"]?.toString(),
        mobileNumber: data["mobileNumber"]?.toString(),
        roleId: roleId,
        roleName: roleName,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await _cacheUser(localUser);
      return localUser;
    }
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put<UserModel>(
        "${ApiEndpoints.users}/$id",
        data: data,
        fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await _cacheUser(response.data!);
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      // Local SQLite fallback
      final db = await _db.database;
      final updateData = <String, dynamic>{};
      if (data.containsKey("fullName")) updateData["FullName"] = data["fullName"];
      if (data.containsKey("email")) updateData["Email"] = data["email"];
      if (data.containsKey("mobileNumber")) updateData["MobileNumber"] = data["mobileNumber"];
      if (data.containsKey("roleId")) updateData["RoleId"] = data["roleId"];
      if (updateData.isNotEmpty) {
        await db.update(DatabaseTables.localUser, updateData, where: "UserId = ?", whereArgs: [id]);
      }
      final localList = await getLocalUsers();
      return localList.firstWhere(
        (u) => u.id == id,
        orElse: () => UserModel.fromSqlite(Map<String, dynamic>.from(updateData)..["UserId"] = id),
      );
    }
  }

  Future<bool> updateUserStatus(int id, bool isActive) async {
    try {
      final response = await _dioClient.patch<bool>(
        "${ApiEndpoints.users}/$id/status",
        data: {"isActive": isActive},
        fromJson: (json) => json as bool? ?? true,
      );
      if (response.success) {
        final db = await _db.database;
        await db.update(DatabaseTables.localUser, {"IsActive": isActive ? 1 : 0}, where: "UserId = ?", whereArgs: [id]);
        return true;
      }
    } catch (_) {
      final db = await _db.database;
      await db.update(DatabaseTables.localUser, {"IsActive": isActive ? 1 : 0}, where: "UserId = ?", whereArgs: [id]);
      return true;
    }
    return false;
  }

  Future<List<RoleModel>> getRoles() async {
    final response = await _dioClient.get(ApiEndpoints.roles);
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<PermissionModel>> getPermissions() async {
    final response = await _dioClient.get(ApiEndpoints.permissions);
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => PermissionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> updateRolePermissions(int roleId, List<int> permissionIds) async {
    final response = await _dioClient.put<bool>(
      "${ApiEndpoints.roles}/$roleId/permissions",
      data: {"permissionIds": permissionIds},
      fromJson: (json) => json as bool? ?? true,
    );
    return response.success;
  }

  Future<List<LoginAuditLogModel>> getAuditLogs({int limit = 50}) async {
    final response = await _dioClient.get(
      "${ApiEndpoints.users}/audit-logs",
      queryParameters: {"limit": limit},
    );
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => LoginAuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<UserModel>> getLocalUsers({
    String? search,
    int? roleId,
    bool? isActive,
    int? companyId,
    bool excludeCashiers = false,
    bool onlyCashiers = false,
  }) async {
    try {
      final db = await _db.database;
      String whereClause = "1=1";
      final List<dynamic> whereArgs = [];

      if (search != null && search.isNotEmpty) {
        whereClause += " AND (u.FullName LIKE ? OR u.Username LIKE ?)";
        whereArgs.add("%$search%");
        whereArgs.add("%$search%");
      }
      if (roleId != null && roleId > 0) {
        whereClause += " AND u.RoleId = ?";
        whereArgs.add(roleId);
      }
      if (excludeCashiers) {
        whereClause += " AND u.RoleId != 3";
      }
      if (onlyCashiers) {
        whereClause += " AND u.RoleId = 3";
      }
      if (companyId != null && companyId > 0) {
        whereClause += " AND (u.CompanyId IS NULL OR u.CompanyId = ? OR u.CompanyId = 0)";
        whereArgs.add(companyId);
      }
      if (isActive != null) {
        whereClause += " AND u.IsActive = ?";
        whereArgs.add(isActive ? 1 : 0);
      }

      final rows = await db.rawQuery("""
        SELECT u.*, c.CompanyName 
        FROM ${DatabaseTables.localUser} u
        LEFT JOIN ${DatabaseTables.localCompany} c ON u.CompanyId = c.CompanyId
        WHERE $whereClause
        ORDER BY u.UserId ASC
      """, whereArgs.isNotEmpty ? whereArgs : null);

      return rows.map((r) => UserModel.fromSqlite(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheUsersBatch(List<UserModel> users) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      for (final u in users) {
        batch.insert(
          DatabaseTables.localUser,
          u.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> _cacheUser(UserModel user) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localUser,
        user.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
