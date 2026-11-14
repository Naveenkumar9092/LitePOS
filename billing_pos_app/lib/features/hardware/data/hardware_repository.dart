import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/printer_model.dart";

final hardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HardwareRepository(dioClient);
});

class HardwareRepository {
  final DioClient _dioClient;

  HardwareRepository(this._dioClient);

  Future<ApiResponse<List<PrinterConfigurationModel>>> getPrinters() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.hardwarePrinters);
      if (response.success && response.data != null) {
        final list = (response.data as List)
            .map((item) => PrinterConfigurationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<PrinterConfigurationModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<PrinterConfigurationModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<PrinterConfigurationModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<PrinterConfigurationModel>> getDefaultPrinter() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.hardwareDefaultPrinter);
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<PrinterConfigurationModel>> createPrinter(PrinterConfigurationModel config) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.hardwarePrinters,
        data: config.toJson(),
      );
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<PrinterConfigurationModel>> updatePrinter(int id, PrinterConfigurationModel config) async {
    try {
      final response = await _dioClient.put(
        "${ApiEndpoints.hardwarePrinters}/$id",
        data: config.toJson(),
      );
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> deletePrinter(int id) async {
    try {
      final response = await _dioClient.delete("${ApiEndpoints.hardwarePrinters}/$id");
      return ApiResponse<void>(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<PrinterConfigurationModel>> setDefaultPrinter(int id) async {
    try {
      final response = await _dioClient.post("${ApiEndpoints.hardwarePrinters}/$id/set-default");
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<PrinterConfigurationModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<TestPrintResultModel>> generateTestPrint({int? printerId}) async {
    try {
      final queryParams = printerId != null ? {"printerId": printerId} : null;
      final response = await _dioClient.post(
        ApiEndpoints.hardwareTestPrint,
        queryParameters: queryParams,
      );
      if (response.success && response.data != null) {
        final model = TestPrintResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<TestPrintResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<TestPrintResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<TestPrintResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<CashDrawerCommandModel>> openCashDrawer() async {
    try {
      final response = await _dioClient.post(ApiEndpoints.hardwareOpenDrawer);
      if (response.success && response.data != null) {
        final model = CashDrawerCommandModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CashDrawerCommandModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<CashDrawerCommandModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<CashDrawerCommandModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<ReceiptPrintResultModel>> getInvoiceReceipt(int invoiceId, {int? printerId}) async {
    try {
      final queryParams = printerId != null ? {"printerId": printerId} : null;
      final response = await _dioClient.get(
        "${ApiEndpoints.hardwareReceipt}/$invoiceId",
        queryParameters: queryParams,
      );
      if (response.success && response.data != null) {
        final model = ReceiptPrintResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<ReceiptPrintResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<ReceiptPrintResultModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<ReceiptPrintResultModel>(
        success: false,
        message: e.toString(),
      );
    }
  }
}

