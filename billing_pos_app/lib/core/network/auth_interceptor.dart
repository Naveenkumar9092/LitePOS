import "package:dio/dio.dart";
import "../constants/app_constants.dart";
import "../routing/app_router.dart";
import "../routing/route_names.dart";
import "../storage/storage_service.dart";

class AuthInterceptor extends Interceptor {
  final IStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.read(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      if (token.startsWith("offline-token")) {
        // In offline mode, do not dispatch protected cloud HTTP requests to avoid 401 unauthorized errors in browser DevTools.
        if (!options.path.contains("/auth/")) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: "Offline mode active: using local database",
            ),
          );
        }
      } else {
        options.headers["Authorization"] = "Bearer $token";
      }
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
      // Avoid redirect loops during logout or login attempts
      if (!path.contains("/auth/logout") && !path.contains("/auth/login")) {
        final token = await _storageService.read(AppConstants.tokenKey);
        if (token != null && !token.startsWith("offline-token")) {
          await _storageService.delete(AppConstants.tokenKey);
          appRouter.go(RouteNames.login);
        }
      }
    }
    return handler.next(err);
  }
}

