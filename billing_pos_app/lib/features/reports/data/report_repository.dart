import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/report_models.dart";

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportRepository(dioClient);
});

class ReportRepository {
  final DioClient _dioClient;

  ReportRepository(this._dioClient);

  Future<ApiResponse<SalesReportSummaryModel>> getSalesSummary(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsSummary,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final model = SalesReportSummaryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<SalesReportSummaryModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<SalesReportSummaryModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<SalesReportSummaryModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<DailySalesModel>>> getDailySales(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsDaily,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => DailySalesModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<DailySalesModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<DailySalesModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<DailySalesModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<ProductSalesReportModel>>> getProductSales(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsProducts,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => ProductSalesReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<ProductSalesReportModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<ProductSalesReportModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<ProductSalesReportModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<CategorySalesReportModel>>> getCategorySales(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsCategories,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => CategorySalesReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<CategorySalesReportModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<CategorySalesReportModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<CategorySalesReportModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<CashierPerformanceReportModel>>> getCashierPerformance(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsCashiers,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => CashierPerformanceReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<CashierPerformanceReportModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<CashierPerformanceReportModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<CashierPerformanceReportModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<GstSummaryReportModel>> getGstSummary(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsGst,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final model = GstSummaryReportModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<GstSummaryReportModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
      return ApiResponse<GstSummaryReportModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<GstSummaryReportModel>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<HourlySalesModel>>> getHourlySales(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsHourly,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => HourlySalesModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<HourlySalesModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<HourlySalesModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<HourlySalesModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<PaymentModeBreakdownModel>>> getPaymentBreakdown(ReportFilterModel filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reportsPayments,
        queryParameters: filter.toQueryParams(),
      );
      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => PaymentModeBreakdownModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<PaymentModeBreakdownModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<PaymentModeBreakdownModel>>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<List<PaymentModeBreakdownModel>>(
        success: false,
        message: e.toString(),
      );
    }
  }
}

