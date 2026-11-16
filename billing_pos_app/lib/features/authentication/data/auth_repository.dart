import "dart:async";
import "dart:convert";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/constants/app_constants.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/database/offline_data_seeder.dart";
import "../../../core/network/dio_client.dart";
import "../../../core/storage/storage_service.dart";
import "../models/auth_response_model.dart";
import "../models/user_model.dart";

class AuthRepository {
  final DioClient _dioClient;
  final IStorageService _storageService;
  final AppDatabase _db;

  AuthRepository(this._dioClient, this._storageService, this._db);

  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceName,
    bool forceOffline = false,
  }) async {
    if (!forceOffline) {
      try {
        final response = await _dioClient.post<AuthResponseModel>(
          ApiEndpoints.login,
          data: {
            "username": username,
            "password": password,
            "deviceId": deviceId,
            "deviceName": deviceName,
          },
          fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
        ).timeout(const Duration(milliseconds: 2000));

        if (response.success && response.data != null) {
          final authData = response.data!;
          // Save tokens in secure storage
          await _storageService.write(AppConstants.tokenKey, authData.accessToken);
          await _storageService.write(AppConstants.refreshTokenKey, authData.refreshToken);
          await _storageService.write("current_user_json", jsonEncode(authData.user.toJson()));
          await _storageService.write("user_role", authData.user.roleName);

          // Cache user to local SQLite
          await _cacheUserToSqlite(authData.user);

          return authData;
        }
      } catch (_) {
        // Cloud unreachable or timed out -> Fallback immediately to offline login!
      }
    }

    // Offline Login Fallback
    return await _loginOffline(username: username, password: password);
  }

  Future<AuthResponseModel> _loginOffline({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) {
      throw Exception("Please enter a username.");
    }

    // Ensure initial offline seed data exists in SQLite
    await OfflineDataSeeder.seedIfEmpty(_db);

    UserModel? matchedUser;
    List<String> permissions = [];

    // Predefined offline roles
    if (cleanUsername == "sadmin" || cleanUsername == "superadmin") {
      matchedUser = UserModel(
        id: 1,
        companyId: 1,
        shopId: 1,
        fullName: "Super Administrator",
        username: "sadmin",
        email: "sadmin@litepos.com",
        mobileNumber: "9876543210",
        roleId: 1,
        roleName: "SAdmin",
        shopName: "Pooja Main Store",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      permissions = const [
        "dashboard.view", "sadmin.access", "company.manage", "users.manage",
        "roles.manage", "billing.create", "orders.view", "orders.manage",
        "products.manage", "reports.view", "sync.manage", "hardware.manage",
      ];
    } else if (cleanUsername == "admin" || cleanUsername == "shopadmin") {
      matchedUser = UserModel(
        id: 2,
        companyId: 1,
        shopId: 1,
        fullName: "Shop Administrator",
        username: "admin",
        email: "admin@litepos.com",
        mobileNumber: "9876543211",
        roleId: 2,
        roleName: "Admin",
        shopName: "Pooja Main Store",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      permissions = const [
        "dashboard.view", "company.manage", "users.manage", "billing.create",
        "orders.view", "orders.manage", "products.manage", "reports.view",
        "hardware.manage", "sync.manage",
      ];
    } else if (cleanUsername == "cashier" || cleanUsername == "operator") {
      matchedUser = UserModel(
        id: 3,
        companyId: 1,
        shopId: 1,
        fullName: "Billing Cashier",
        username: "cashier",
        email: "cashier@litepos.com",
        mobileNumber: "9876543212",
        roleId: 3,
        roleName: "Cashier",
        shopName: "Pooja Main Store",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      permissions = const [
        "dashboard.view", "billing.create", "orders.view", "pos.operate",
      ];
    } else {
      // Check SQLite local user table
      try {
        final db = await _db.database;
        final rows = await db.query(
          DatabaseTables.localUser,
          where: "LOWER(Username) = ?",
          whereArgs: [cleanUsername],
        );
        if (rows.isNotEmpty) {
          matchedUser = UserModel.fromSqlite(rows.first);
          permissions = matchedUser.isSAdmin
              ? const ["dashboard.view", "sadmin.access", "company.manage", "users.manage", "billing.create", "orders.view"]
              : (matchedUser.isAdmin
                  ? const ["dashboard.view", "company.manage", "billing.create", "orders.view", "products.manage"]
                  : const ["dashboard.view", "billing.create", "orders.view", "pos.operate"]);
        }
      } catch (_) {}
    }

    if (matchedUser == null) {
      throw Exception("User '$username' not found. In offline mode, use 'sadmin', 'admin', or 'cashier'.");
    }

    final offlineToken = "offline-token-${matchedUser.id}-${DateTime.now().millisecondsSinceEpoch}";
    final offlineRefresh = "offline-refresh-${matchedUser.id}";

    await _storageService.write(AppConstants.tokenKey, offlineToken);
    await _storageService.write(AppConstants.refreshTokenKey, offlineRefresh);
    await _storageService.write("current_user_json", jsonEncode(matchedUser.toJson()));
    await _storageService.write("user_role", matchedUser.roleName);
    await _cacheUserToSqlite(matchedUser);

    return AuthResponseModel(
      accessToken: offlineToken,
      refreshToken: offlineRefresh,
      expiresAtUtc: DateTime.now().add(const Duration(days: 30)),
      user: matchedUser,
      permissions: permissions,
    );
  }

  Future<AuthResponseModel?> refreshToken() async {
    final refreshToken = await _storageService.read(AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _dioClient.post<AuthResponseModel>(
      ApiEndpoints.refreshToken,
      data: {
        "refreshToken": refreshToken,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      final authData = response.data!;
      await _storageService.write(AppConstants.tokenKey, authData.accessToken);
      await _storageService.write(AppConstants.refreshTokenKey, authData.refreshToken);
      await _storageService.write("current_user_json", jsonEncode(authData.user.toJson()));
      return authData;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.read(AppConstants.refreshTokenKey);
      await _dioClient.post(
        ApiEndpoints.logout,
        data: {"refreshToken": refreshToken},
      );
    } catch (_) {
      // Offline or network error during logout should still clear local tokens
    } finally {
      await _storageService.delete(AppConstants.tokenKey);
      await _storageService.delete(AppConstants.refreshTokenKey);
      await _storageService.delete("current_user_json");
      await _storageService.delete("user_role");
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _dioClient.post<bool>(
      ApiEndpoints.changePassword,
      data: {
        "currentPassword": currentPassword,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      },
      fromJson: (json) => json as bool? ?? true,
    );
    return response.success;
  }

  Future<bool> forgotPassword(String usernameOrEmail) async {
    final response = await _dioClient.post<bool>(
      ApiEndpoints.forgotPassword,
      data: {
        "usernameOrEmail": usernameOrEmail,
      },
      fromJson: (json) => json as bool? ?? true,
    );
    return response.success;
  }

  Future<UserModel?> getCachedUser() async {
    final userJson = await _storageService.read("current_user_json");
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _cacheUserToSqlite(UserModel user) async {
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
