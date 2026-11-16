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
      await _storageService.delete(AppConstants.tokenKey);
      appRouter.go(RouteNames.login);
    }
    return handler.next(err);
  }
}

