import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/reports/models/report_models.dart";
import "package:billing_pos_app/features/reports/presentation/reports_screen.dart";
import "package:billing_pos_app/features/reports/presentation/report_state.dart";

class FakeReportNotifier extends StateNotifier<ReportState> implements ReportNotifier {
  FakeReportNotifier(super.state);

  @override
  void setTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  @override
  void filterToday() {}

  @override
  void filterYesterday() {}

  @override
  void filterThisWeek() {}

  @override
  void filterThisMonth() {}

  @override
  void setCustomRange(DateTime from, DateTime to) {}

  @override
  Future<void> loadReports() async {}
}

void main() {
  final testSummary = SalesReportSummaryModel(
    fromDateUtc: DateTime.utc(2026, 11, 13),
    toDateUtc: DateTime.utc(2026, 11, 13, 23, 59, 59),
    totalInvoices: 8,
    totalActiveInvoices: 8,
    totalCancelledInvoices: 0,
    grossSales: 3200.0,
    totalDiscount: 100.0,
    netSales: 3100.0,
    totalTax: 155.0,
    grandTotalSales: 3255.0,
    totalRefunds: 50.0,
    netRevenue: 3205.0,
    totalCashCollected: 2000.0,
    totalUpiCollected: 1255.0,
    totalCardCollected: 0.0,
    totalDueOutstanding: 0.0,
    averageOrderValue: 406.88,
  );

  final testPayments = [
    const PaymentModeBreakdownModel(
      paymentMode: "Cash",
      transactionCount: 5,
      totalAmount: 2000.0,
      percentage: 61.4,
    ),
    const PaymentModeBreakdownModel(
      paymentMode: "UPI",
      transactionCount: 3,
      totalAmount: 1255.0,
      percentage: 38.6,
    ),
  ];

  final testHourly = [
    const HourlySalesModel(
      hour: 10,
      timeSlot: "10:00 AM - 11:00 AM",
      orderCount: 3,
      totalSales: 1200.0,
    ),
  ];

  final testInitialState = ReportState(
    filter: ReportFilterModel.today(),
    summary: testSummary,
    paymentBreakdown: testPayments,
    hourlySales: testHourly,
    isLoading: false,
  );

  Widget createWidgetForTesting(ReportState state) {
    return ProviderScope(
      overrides: [
        reportNotifierProvider.overrideWith((ref) => FakeReportNotifier(state)),
      ],
      child: const MaterialApp(
        home: ReportsScreen(),
      ),
    );
  }

  group("ReportsScreen Widget Tests", () {
    testWidgets("ReportsScreen renders app bar, tabs, and filter chips", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetForTesting(testInitialState));
      await tester.pumpAndSettle();

      expect(find.text("Reports & Business Analytics"), findsOneWidget);
      expect(find.text("Today"), findsOneWidget);
      expect(find.text("Yesterday"), findsOneWidget);
      expect(find.text("This Week"), findsOneWidget);
      expect(find.text("This Month"), findsOneWidget);

      expect(find.text("Sales Overview"), findsOneWidget);
      expect(find.text("Daily Sales"), findsOneWidget);
      expect(find.text("Items & Categories"), findsOneWidget);
      expect(find.text("Cashier Performance"), findsOneWidget);
      expect(find.text("GST & Tax Summary"), findsOneWidget);
    });

    testWidgets("ReportsScreen renders Overview Tab KPI cards and payment breakdown", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetForTesting(testInitialState));
      await tester.pumpAndSettle();

      expect(find.text("Total Revenue"), findsOneWidget);
      expect(find.text("Gross Sales"), findsOneWidget);
      expect(find.text("GST Collected"), findsOneWidget);
      expect(find.text("Total Discounts"), findsOneWidget);
      expect(find.text("Avg Bill Value"), findsOneWidget);
      expect(find.text("Payment Mode Distribution"), findsOneWidget);
      expect(find.text("Peak Rush Hours (Cafe / Desserts)"), findsOneWidget);
      expect(find.text("10:00 AM - 11:00 AM"), findsOneWidget);
    });
  });
}

