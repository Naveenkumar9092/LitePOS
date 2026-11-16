import "package:dio/dio.dart";
import "../constants/api_endpoints.dart";
import "../storage/storage_service.dart";
import "api_response.dart";
import "auth_interceptor.dart";
import "network_exceptions.dart";

class DioClient {
  late final Dio _dio;

  DioClient(IStorageService storageService, {String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: const Duration(milliseconds: 3000),
        receiveTimeout: const Duration(milliseconds: 4000),
        sendTimeout: const Duration(milliseconds: 4000),
      ),
    );

    _dio.interceptors.add(AuthInterceptor(storageService));

    storageService.read("custom_server_url").then((customUrl) {
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        setBaseUrl(customUrl.trim());
      }
    }).catchError((_) {});
  }

  void setBaseUrl(String newUrl) {
    if (newUrl.trim().isNotEmpty) {
      _dio.options.baseUrl = newUrl.trim();
    }
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}

