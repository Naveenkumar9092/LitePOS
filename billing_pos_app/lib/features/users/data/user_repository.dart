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
  }) async {
    final queryParams = <String, dynamic>{
      "pageNumber": pageNumber,
      "pageSize": pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams["search"] = search;
    if (roleId != null && roleId > 0) queryParams["roleId"] = roleId;
    if (isActive != null) queryParams["isActive"] = isActive;

    try {
      final response = await _dioClient.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rawItems = data["items"] as List<dynamic>? ?? [];
        final items = rawItems.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
        final totalCount = (data["totalCount"] as num?)?.toInt() ?? items.length;

        // Cache fetched users locally in background
        unawaited(_cacheUsersBatch(items));

        return PagedUsersResult(
          items: items,
          totalCount: totalCount,
          pageIndex: pageNumber,
          pageSize: pageSize,
        );
      }
    } catch (_) {
      // Offline fallback: load from SQLite
      final localItems = await getLocalUsers(search: search, roleId: roleId, isActive: isActive);
      return PagedUsersResult(
        items: localItems,
        totalCount: localItems.length,
        pageIndex: pageNumber,
        pageSize: pageSize,
      );
    }

    return PagedUsersResult(items: [], totalCount: 0, pageIndex: 1, pageSize: pageSize);
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
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
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) async {
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
  }

  Future<bool> updateUserStatus(int id, bool isActive) async {
    final response = await _dioClient.patch<bool>(
      "${ApiEndpoints.users}/$id/status",
      data: {"isActive": isActive},
      fromJson: (json) => json as bool? ?? true,
    );
    return response.success;
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

  Future<List<UserModel>> getLocalUsers({String? search, int? roleId, bool? isActive}) async {
    try {
      final db = await _db.database;
      String whereClause = "1=1";
      final List<dynamic> whereArgs = [];

      if (search != null && search.isNotEmpty) {
        whereClause += " AND (FullName LIKE ? OR Username LIKE ?)";
        whereArgs.add("%$search%");
        whereArgs.add("%$search%");
      }
      if (roleId != null && roleId > 0) {
        whereClause += " AND RoleId = ?";
        whereArgs.add(roleId);
      }
      if (isActive != null) {
        whereClause += " AND IsActive = ?";
        whereArgs.add(isActive ? 1 : 0);
      }

      final rows = await db.query(
        DatabaseTables.localUser,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );

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
