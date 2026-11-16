import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/report_repository.dart";
import "../models/report_models.dart";

class ReportState {
  final ReportFilterModel filter;
  final SalesReportSummaryModel? summary;
  final List<DailySalesModel> dailySales;
  final List<ProductSalesReportModel> productSales;
  final List<CategorySalesReportModel> categorySales;
  final List<CashierPerformanceReportModel> cashierSales;
  final GstSummaryReportModel? gstSummary;
  final List<HourlySalesModel> hourlySales;
  final List<PaymentModeBreakdownModel> paymentBreakdown;
  final bool isLoading;
  final String? errorMessage;
  final int selectedTabIndex;

  const ReportState({
    required this.filter,
    this.summary,
    this.dailySales = const [],
    this.productSales = const [],
    this.categorySales = const [],
    this.cashierSales = const [],
    this.gstSummary,
    this.hourlySales = const [],
    this.paymentBreakdown = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTabIndex = 0,
  });

  ReportState copyWith({
    ReportFilterModel? filter,
    SalesReportSummaryModel? summary,
    List<DailySalesModel>? dailySales,
    List<ProductSalesReportModel>? productSales,
    List<CategorySalesReportModel>? categorySales,
    List<CashierPerformanceReportModel>? cashierSales,
    GstSummaryReportModel? gstSummary,
    List<HourlySalesModel>? hourlySales,
    List<PaymentModeBreakdownModel>? paymentBreakdown,
    bool? isLoading,
    String? errorMessage,
    int? selectedTabIndex,
  }) {
    return ReportState(
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      dailySales: dailySales ?? this.dailySales,
      productSales: productSales ?? this.productSales,
      categorySales: categorySales ?? this.categorySales,
      cashierSales: cashierSales ?? this.cashierSales,
      gstSummary: gstSummary ?? this.gstSummary,
      hourlySales: hourlySales ?? this.hourlySales,
      paymentBreakdown: paymentBreakdown ?? this.paymentBreakdown,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

final reportNotifierProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(repository);
});

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;

  ReportNotifier(this._repository) : super(ReportState(filter: ReportFilterModel.today())) {
    loadReports();
  }

  void setTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void filterToday() {
    state = state.copyWith(filter: ReportFilterModel.today());
    loadReports();
  }

  void filterYesterday() {
    state = state.copyWith(filter: ReportFilterModel.yesterday());
    loadReports();
  }

  void filterThisWeek() {
    state = state.copyWith(filter: ReportFilterModel.thisWeek());
    loadReports();
  }

  void filterThisMonth() {
    state = state.copyWith(filter: ReportFilterModel.thisMonth());
    loadReports();
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(filter: ReportFilterModel.custom(from, to));
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final summaryRes = await _repository.getSalesSummary(state.filter);
      final dailyRes = await _repository.getDailySales(state.filter);
      final productRes = await _repository.getProductSales(state.filter);
      final catRes = await _repository.getCategorySales(state.filter);
      final cashierRes = await _repository.getCashierPerformance(state.filter);
      final gstRes = await _repository.getGstSummary(state.filter);
      final hourlyRes = await _repository.getHourlySales(state.filter);
      final paymentRes = await _repository.getPaymentBreakdown(state.filter);

      state = state.copyWith(
        isLoading: false,
        summary: summaryRes.data,
        dailySales: dailyRes.data ?? [],
        productSales: productRes.data ?? [],
        categorySales: catRes.data ?? [],
        cashierSales: cashierRes.data ?? [],
        gstSummary: gstRes.data,
        hourlySales: hourlyRes.data ?? [],
        paymentBreakdown: paymentRes.data ?? [],
        errorMessage: summaryRes.success ? null : summaryRes.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

