import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/notification_models.dart";

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRepository(dioClient);
});

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository(this._dioClient);

  Future<ApiResponse<NotificationResultModel>> sendInvoiceEmail(SendInvoiceNotificationModel request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.emailInvoice,
        data: request.toJson(),
      );
      if (response.success && response.data != null) {
        final model = NotificationResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<NotificationResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<NotificationResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<NotificationResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<NotificationResultModel>> sendInvoiceWhatsApp(SendInvoiceNotificationModel request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.whatsappInvoice,
        data: request.toJson(),
      );
      if (response.success && response.data != null) {
        final model = NotificationResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<NotificationResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<NotificationResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<NotificationResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<NotificationAuditLogModel>>> getNotificationLogs({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.notificationLogs,
        queryParameters: {
          "page": page,
          "pageSize": pageSize,
        },
      );
      if (response.success && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final itemsList = (dataMap["items"] as List? ?? [])
            .map((item) => NotificationAuditLogModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<NotificationAuditLogModel>>(
          success: true,
          message: response.message,
          data: itemsList,
        );
      }
      return ApiResponse<List<NotificationAuditLogModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<NotificationAuditLogModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<ShopPreferenceModel>> getPreferences() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.settingsPreferences);
      if (response.success && response.data != null) {
        final model = ShopPreferenceModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<ShopPreferenceModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<ShopPreferenceModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<ShopPreferenceModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<ShopPreferenceModel>> updatePreferences(ShopPreferenceModel preferences) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.settingsPreferences,
        data: preferences.toJson(),
      );
      if (response.success && response.data != null) {
        final model = ShopPreferenceModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<ShopPreferenceModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<ShopPreferenceModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<ShopPreferenceModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<DatabaseBackupResultModel>> createDatabaseBackup() async {
    try {
      final response = await _dioClient.post(ApiEndpoints.settingsBackup);
      if (response.success && response.data != null) {
        final model = DatabaseBackupResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<DatabaseBackupResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<DatabaseBackupResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<DatabaseBackupResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<SystemInfoSummaryModel>> getSystemInfo() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.settingsSystemInfo);
      if (response.success && response.data != null) {
        final model = SystemInfoSummaryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<SystemInfoSummaryModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<SystemInfoSummaryModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<SystemInfoSummaryModel>(
        success: false,
        message: e.toString(),
      );
    }
  }
}

