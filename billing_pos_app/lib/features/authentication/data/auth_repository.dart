import "dart:async";
import "dart:convert";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/constants/app_constants.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/network/dio_client.dart";
import "../../../core/network/network_exceptions.dart";
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
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw Exception("Please enter username.");
    }
    if (password.trim().isEmpty) {
      throw Exception("Please enter password.");
    }

    final isSAdminAttempt = cleanUsername.toLowerCase() == "sadmin" ||
        cleanUsername.toLowerCase() == "superadmin";

    // Strict requirement: All logins must authenticate online with the cloud/backend API.
    // Offline login fallback is strictly disabled for session creation.
    try {
      final response = await _dioClient.post<AuthResponseModel>(
        ApiEndpoints.login,
        data: {
          "username": cleanUsername,
          "password": password,
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
        fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
      ).timeout(const Duration(seconds: 10));

      if (response.success && response.data != null) {
        final authData = response.data!;
        // Save tokens in secure storage & shared preferences
        await _storageService.write(AppConstants.tokenKey, authData.accessToken);
        await _storageService.write(AppConstants.refreshTokenKey, authData.refreshToken);
        await _storageService.write("current_user_json", jsonEncode(authData.user.toJson()));
        await _storageService.write("user_role", authData.user.roleName);

        // Cache user to local SQLite for profile references
        await _cacheUserToSqlite(authData.user);
        await _handleMultiCompanyIsolation(authData.user);

        return authData;
      } else {
        throw Exception(response.message.isNotEmpty ? response.message : "Invalid username or password.");
      }
    } catch (e) {
      if (e is NetworkException) {
        if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
          throw Exception(e.message);
        } else if (e.statusCode != null && e.statusCode! >= 500) {
          throw Exception("Server Error (${e.statusCode}): ${e.message}");
        }
      }

      final errorStr = e.toString();
      if (errorStr.contains("Invalid username or password") ||
          errorStr.contains("disabled") ||
          errorStr.contains("Unauthorized") ||
          errorStr.contains("locked") ||
          errorStr.contains("credentials")) {
        rethrow;
      }

      // Network / Connectivity failure:
      if (isSAdminAttempt) {
        throw Exception("Super Administrator requires an active internet connection to log in.");
      } else {
        throw Exception("An active internet connection is required to log in. Please connect to the internet.");
      }
    }
  }

  /// Checks whether the backend API is online and reachable
  Future<bool> isOnline() async {
    try {
      final res = await _dioClient.get(ApiEndpoints.ping).timeout(const Duration(seconds: 8));
      return res.success;
    } catch (_) {
      return false;
    }
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
      final token = await _storageService.read(AppConstants.tokenKey);
      final refreshToken = await _storageService.read(AppConstants.refreshTokenKey);
      if (token != null && !token.startsWith("offline-token") && refreshToken != null) {
        await _dioClient.post(
          ApiEndpoints.logout,
          data: {"refreshToken": refreshToken},
        ).timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // Offline or network error during logout should still clear local tokens
    } finally {
      await _storageService.delete(AppConstants.tokenKey);
      await _storageService.delete(AppConstants.refreshTokenKey);
      await _storageService.delete("current_user_json");
      await _storageService.delete("user_role");
      await _storageService.delete("last_active_company_id");
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

  Future<void> _handleMultiCompanyIsolation(UserModel user) async {
    try {
      final lastCompanyIdStr = await _storageService.read("last_active_company_id");
      final currentCompanyId = user.companyId.toString();

      if (lastCompanyIdStr != null && lastCompanyIdStr != currentCompanyId && !user.isSAdmin) {
        // Multi-tenant isolation: Wipe previous company's cached records so new store starts isolated
        final db = await _db.database;
        await db.delete(DatabaseTables.localProduct);
        await db.delete(DatabaseTables.localInvoiceDetail);
        await db.delete(DatabaseTables.localInvoice);
        await db.delete(DatabaseTables.localCustomer);
      }
      await _storageService.write("last_active_company_id", currentCompanyId);
    } catch (_) {}
  }
}
