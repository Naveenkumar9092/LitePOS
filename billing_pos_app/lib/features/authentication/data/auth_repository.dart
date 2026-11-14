import "dart:convert";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/constants/app_constants.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
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
  }) async {
    final response = await _dioClient.post<AuthResponseModel>(
      ApiEndpoints.login,
      data: {
        "username": username,
        "password": password,
        "deviceId": deviceId,
        "deviceName": deviceName,
      },
      fromJson: (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
    );

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
    } else {
      throw Exception(response.message);
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
