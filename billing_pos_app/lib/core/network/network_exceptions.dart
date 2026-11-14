import "package:dio/dio.dart";

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  NetworkException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory NetworkException.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: "Connection timed out. Operating in offline mode.",
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        if (response?.data is Map<String, dynamic>) {
          final data = response!.data as Map<String, dynamic>;
          final msg = data["message"] as String? ?? "An error occurred";
          final errors = (data["errors"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          return NetworkException(
            message: msg,
            statusCode: response.statusCode,
            errors: errors,
          );
        }
        return NetworkException(
          message: "Server returned error: ${response?.statusCode}",
          statusCode: response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: "Server is unreachable. Please verify network connection.",
          statusCode: 503,
        );

      case DioExceptionType.cancel:
        return NetworkException(message: "Request was cancelled");

      default:
        return NetworkException(
          message: dioException.message ?? "An unexpected network error occurred",
        );
    }
  }

  @override
  String toString() => message;
}

