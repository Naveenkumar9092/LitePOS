import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/reports/models/report_models.dart";
import "package:billing_pos_app/features/reports/presentation/report_state.dart";

void main() {
  group("ReportState Tests", () {
    test("ReportState defaults are properly initialized", () {
      final state = ReportState(filter: ReportFilterModel.today());
      expect(state.isLoading, false);
      expect(state.summary, isNull);
      expect(state.dailySales, isEmpty);
      expect(state.productSales, isEmpty);
      expect(state.categorySales, isEmpty);
      expect(state.cashierSales, isEmpty);
      expect(state.gstSummary, isNull);
      expect(state.hourlySales, isEmpty);
      expect(state.paymentBreakdown, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.selectedTabIndex, 0);
      expect(state.filter.rangeType, ReportDateRangeType.today);
    });

    test("ReportState copyWith updates fields properly", () {
      final state = ReportState(filter: ReportFilterModel.today());
      final summary = SalesReportSummaryModel(
        fromDateUtc: DateTime.utc(2026, 11, 13),
        toDateUtc: DateTime.utc(2026, 11, 13, 23, 59, 59),
        totalInvoices: 5,
        totalActiveInvoices: 5,
        totalCancelledInvoices: 0,
        grossSales: 1500.0,
        totalDiscount: 50.0,
        netSales: 1450.0,
        totalTax: 72.5,
        grandTotalSales: 1522.5,
        totalRefunds: 0.0,
        netRevenue: 1522.5,
        totalCashCollected: 1000.0,
        totalUpiCollected: 522.5,
        totalCardCollected: 0.0,
        totalDueOutstanding: 0.0,
        averageOrderValue: 304.5,
      );

      final updated = state.copyWith(
        isLoading: true,
        summary: summary,
        selectedTabIndex: 2,
      );

      expect(updated.isLoading, true);
      expect(updated.summary, isNotNull);
      expect(updated.summary!.netRevenue, 1522.5);
      expect(updated.selectedTabIndex, 2);
    });
  });
}

