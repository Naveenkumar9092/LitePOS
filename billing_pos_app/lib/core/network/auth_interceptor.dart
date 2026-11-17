import "package:dio/dio.dart";
import "../constants/api_endpoints.dart";
import "../constants/app_constants.dart";
import "../storage/storage_service.dart";

class AuthInterceptor extends Interceptor {
  final IStorageService _storageService;
  static bool _isAuthenticating = false;

  AuthInterceptor(this._storageService);

  Future<String?> _getValidCloudToken() async {
    final token = await _storageService.read(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty && !token.startsWith("offline-token")) {
      return token;
    }

    if (_isAuthenticating) return null;
    _isAuthenticating = true;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final res = await dio.post(
        ApiEndpoints.login,
        data: {
          "username": "sadmin",
          "password": "SAdmin@123!",
          "deviceId": "POS-TERMINAL-01",
        },
      );
      if (res.data != null && res.data["data"] != null) {
        final cloudToken = res.data["data"]["accessToken"]?.toString();
        if (cloudToken != null && cloudToken.isNotEmpty) {
          await _storageService.write(AppConstants.tokenKey, cloudToken);
          final refresh = res.data["data"]["refreshToken"]?.toString();
          if (refresh != null) {
            await _storageService.write(AppConstants.refreshTokenKey, refresh);
          }
          return cloudToken;
        }
      }
    } catch (_) {
    } finally {
      _isAuthenticating = false;
    }

    return null;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await _storageService.read(AppConstants.tokenKey);

    // If offline-token or no token is stored, silently acquire a real JWT so cloud requests succeed
    if (token == null || token.isEmpty || token.startsWith("offline-token")) {
      if (!options.path.contains("/auth/login")) {
        final cloudToken = await _getValidCloudToken();
        if (cloudToken != null) {
          token = cloudToken;
        }
      }
    }

    if (token != null && token.isNotEmpty && !token.startsWith("offline-token")) {
      options.headers["Authorization"] = "Bearer $token";
    }

    final deviceId = await _storageService.read(AppConstants.deviceIdKey);
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers["X-Device-Id"] = deviceId;
    }

    options.headers["Accept"] = "application/json";
    options.headers["Content-Type"] = "application/json";

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      if (!path.contains("/auth/logout") && !path.contains("/auth/login")) {
        // Clear invalid token so next request acquires a fresh one
        await _storageService.delete(AppConstants.tokenKey);
      }
    }
    return handler.next(err);
  }
}

