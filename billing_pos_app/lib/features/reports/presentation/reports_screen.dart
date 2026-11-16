import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/shared/widgets/error_view.dart";
import "../models/report_models.dart";
import "report_state.dart";

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(reportNotifierProvider.notifier).setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: ref.read(reportNotifierProvider).filter.fromDateUtc.toLocal(),
        end: ref.read(reportNotifierProvider).filter.toDateUtc.toLocal(),
      ),
    );

    if (picked != null) {
      final fromUtc = DateTime.utc(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      final toUtc = DateTime.utc(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
      ref.read(reportNotifierProvider.notifier).setCustomRange(fromUtc, toUtc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportNotifierProvider);
    final notifier = ref.read(reportNotifierProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? "Reports" : "Reports & Business Analytics"),
        actions: [
          // Softcopy PDF Report
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
              tooltip: "Softcopy Report (PDF)",
              onPressed: () async {
                final pdfBytes = await SoftcopyService.instance.generateReportPdf(state: state);
                if (!context.mounted) return;
                await SoftcopyService.instance.previewOrPrintPdf(
                  context: context,
                  pdfBytes: pdfBytes,
                  title: "Business Analytics Report",
                  fileName: "Report_${DateFormat('yyyyMMdd').format(state.filter.fromDateUtc)}_${DateFormat('yyyyMMdd').format(state.filter.toDateUtc)}.pdf",
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.table_chart_outlined, color: AppColors.success),
              tooltip: "Export CSV",
              onPressed: () async {
                final csv = SoftcopyService.instance.generateReportCsv(state);
                final path = await SoftcopyService.instance.saveCsvToFile(
                  csvContent: csv,
                  defaultFileName: "Report_${DateFormat('yyyyMMdd').format(state.filter.fromDateUtc)}.csv",
                );
                if (!context.mounted) return;
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Report CSV exported: $path"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text("Softcopy Report (PDF)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final pdfBytes = await SoftcopyService.instance.generateReportPdf(state: state);
                  if (!context.mounted) return;
                  await SoftcopyService.instance.previewOrPrintPdf(
                    context: context,
                    pdfBytes: pdfBytes,
                    title: "Business Analytics Report",
                    fileName: "Report_${DateFormat('yyyyMMdd').format(state.filter.fromDateUtc)}_${DateFormat('yyyyMMdd').format(state.filter.toDateUtc)}.pdf",
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Softcopy CSV Export
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.table_chart_outlined, size: 16, color: AppColors.success),
                label: const Text("Export CSV", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final csv = SoftcopyService.instance.generateReportCsv(state);
                  final path = await SoftcopyService.instance.saveCsvToFile(
                    csvContent: csv,
                    defaultFileName: "Report_${DateFormat('yyyyMMdd').format(state.filter.fromDateUtc)}.csv",
                  );
                  if (!context.mounted) return;
                  if (path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Report CSV exported: $path"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
          ],

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Reports",
            onPressed: () => notifier.loadReports(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // Date filter chip row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text("Today"),
                        selected: state.filter.rangeType == ReportDateRangeType.today,
                        onSelected: (_) => notifier.filterToday(),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("Yesterday"),
                        selected: state.filter.rangeType == ReportDateRangeType.yesterday,
                        onSelected: (_) => notifier.filterYesterday(),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("This Week"),
                        selected: state.filter.rangeType == ReportDateRangeType.thisWeek,
                        onSelected: (_) => notifier.filterThisWeek(),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("This Month"),
                        selected: state.filter.rangeType == ReportDateRangeType.thisMonth,
                        onSelected: (_) => notifier.filterThisMonth(),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_month, size: 18),
                        label: Text(state.filter.rangeType == ReportDateRangeType.custom
                            ? "${DateFormat('dd/MM').format(state.filter.fromDateUtc)} - ${DateFormat('dd/MM').format(state.filter.toDateUtc)}"
                            : "Custom Range"),
                        onPressed: _pickCustomRange,
                      ),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_outlined), text: "Sales Overview"),
                  Tab(icon: Icon(Icons.calendar_today_outlined), text: "Daily Sales"),
                  Tab(icon: Icon(Icons.fastfood_outlined), text: "Items & Categories"),
                  Tab(icon: Icon(Icons.people_outline), text: "Cashier Performance"),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: "GST & Tax Summary"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.summary == null
              ? Center(
                  child: ErrorView(
                    message: state.errorMessage!,
                    onRetry: () => notifier.loadReports(),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(state, isMobile),
                    _buildDailySalesTab(state),
                    _buildItemsAndCategoriesTab(state),
                    _buildCashierPerformanceTab(state),
                    _buildGstSummaryTab(state),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(ReportState state, bool isMobile) {
    final summary = state.summary;
    if (summary == null) {
      return const Center(child: Text("No report data available for this range."));
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = isMobile ? (screenWidth - 44) / 2 : 220.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Cards Grid
          Wrap(
            spacing: isMobile ? 8 : 16,
            runSpacing: isMobile ? 8 : 16,
            children: [
              _buildMetricCard(
                title: "Total Revenue",
                value: CurrencyFormatter.format(summary.netRevenue),
                subtitle: "${summary.totalActiveInvoices} Active Bills",
                icon: Icons.payments,
                color: AppColors.primary,
                width: cardWidth,
              ),
              _buildMetricCard(
                title: "Gross Sales",
                value: CurrencyFormatter.format(summary.grossSales),
                subtitle: "Before Discounts & Tax",
                icon: Icons.point_of_sale,
                color: Colors.blueGrey,
                width: cardWidth,
              ),
              _buildMetricCard(
                title: "GST Collected",
                value: CurrencyFormatter.format(summary.totalTax),
                subtitle: "CGST + SGST Combined",
                icon: Icons.account_balance,
                color: Colors.teal,
                width: cardWidth,
              ),
              _buildMetricCard(
                title: "Total Discounts",
                value: CurrencyFormatter.format(summary.totalDiscount),
                subtitle: "Savings Given",
                icon: Icons.discount,
                color: Colors.deepOrange,
                width: cardWidth,
              ),
              _buildMetricCard(
                title: "Avg Bill Value",
                value: CurrencyFormatter.format(summary.averageOrderValue),
                subtitle: "Per Customer",
                icon: Icons.shopping_basket,
                color: Colors.indigo,
                width: cardWidth,
              ),
              _buildMetricCard(
                title: "Refunds",
                value: CurrencyFormatter.format(summary.totalRefunds),
                subtitle: "Returns Processed",
                icon: Icons.replay,
                color: Colors.red,
                width: cardWidth,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Distribution Section
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Mode Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.paymentBreakdown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No payments recorded in this period."),
                  )
                else
                  ...state.paymentBreakdown.map((pm) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isMobile ? 70 : 100,
                              child: Text(
                                pm.paymentMode,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (pm.percentage / 100).clamp(0.0, 1.0),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${CurrencyFormatter.format(pm.totalAmount)} (${pm.percentage.toStringAsFixed(1)}%)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Peak Hourly Sales Section
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Peak Rush Hours (Cafe / Desserts)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.hourlySales.every((h) => h.orderCount == 0))
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No sales activity during this period."),
                  )
                else
                  ...state.hourlySales.where((h) => h.orderCount > 0).map((h) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(h.timeSlot, style: const TextStyle(fontSize: 12)),
                            ),
                            Badge(
                              label: Text("${h.orderCount} orders", style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(h.totalSales),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesTab(ReportState state) {
    if (state.dailySales.isEmpty) {
      return const Center(child: Text("No daily sales recorded for this date range."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Bills Count")),
              DataColumn(label: Text("Gross Sales")),
              DataColumn(label: Text("Discount")),
              DataColumn(label: Text("GST Tax")),
              DataColumn(label: Text("Net Total")),
              DataColumn(label: Text("Cash")),
              DataColumn(label: Text("UPI")),
              DataColumn(label: Text("Card")),
            ],
            rows: state.dailySales.map((d) {
              return DataRow(cells: [
                DataCell(Text(DateFormat("dd MMM yyyy").format(d.date))),
                DataCell(Text("${d.invoiceCount}")),
                DataCell(Text(CurrencyFormatter.format(d.grossSales))),
                DataCell(Text(CurrencyFormatter.format(d.discountAmount))),
                DataCell(Text(CurrencyFormatter.format(d.taxAmount))),
                DataCell(Text(CurrencyFormatter.format(d.netSales), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(d.cashAmount))),
                DataCell(Text(CurrencyFormatter.format(d.upiAmount))),
                DataCell(Text(CurrencyFormatter.format(d.cardAmount))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsAndCategoriesTab(ReportState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Contribution
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sales by Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.categorySales.isEmpty)
                  const Text("No category sales in this period.")
                else
                  ...state.categorySales.map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (cat.percentageOfSales / 100).clamp(0.0, 1.0),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${cat.totalQuantitySold} items | ${CurrencyFormatter.format(cat.totalRevenue)} (${cat.percentageOfSales.toStringAsFixed(1)}%)",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Top Selling Items
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Selling Items (Food & Beverages)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.productSales.isEmpty)
                  const Text("No product sales recorded.")
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Product")),
                        DataColumn(label: Text("Category")),
                        DataColumn(label: Text("Qty Sold")),
                        DataColumn(label: Text("Total Revenue")),
                        DataColumn(label: Text("Tax Amount")),
                        DataColumn(label: Text("% of Sales")),
                      ],
                      rows: state.productSales.map((p) {
                        return DataRow(cells: [
                          DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(p.categoryName)),
                          DataCell(Text("${p.quantitySold}")),
                          DataCell(Text(CurrencyFormatter.format(p.totalRevenue), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(CurrencyFormatter.format(p.totalTax))),
                          DataCell(Text("${p.percentageOfSales.toStringAsFixed(1)}%")),
                        ]);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashierPerformanceTab(ReportState state) {
    if (state.cashierSales.isEmpty) {
      return const Center(child: Text("No cashier performance records for this period."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Cashier Name")),
              DataColumn(label: Text("Username")),
              DataColumn(label: Text("Invoices Count")),
              DataColumn(label: Text("Total Sales")),
              DataColumn(label: Text("Cash Handled")),
              DataColumn(label: Text("Digital (UPI/Card)")),
              DataColumn(label: Text("Refunds Handled")),
            ],
            rows: state.cashierSales.map((c) {
              return DataRow(cells: [
                DataCell(Text(c.cashierName, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(c.username)),
                DataCell(Text("${c.invoicesCount}")),
                DataCell(Text(CurrencyFormatter.format(c.totalSales), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(c.cashCollected))),
                DataCell(Text(CurrencyFormatter.format(c.digitalCollected))),
                DataCell(Text(CurrencyFormatter.format(c.refundsHandled), style: TextStyle(color: c.refundsHandled > 0 ? Colors.red : null))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGstSummaryTab(ReportState state) {
    final gst = state.gstSummary;
    if (gst == null) {
      return const Center(child: Text("No GST summary data available."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slabs Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "GST Tax Slabs Summary (GSTR-1 Ready)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Tax Slab")),
                      DataColumn(label: Text("Taxable Amount")),
                      DataColumn(label: Text("CGST (Central)")),
                      DataColumn(label: Text("SGST (State)")),
                      DataColumn(label: Text("Total GST")),
                    ],
                    rows: [
                      ...gst.slabs.map((s) => DataRow(cells: [
                            DataCell(Text("${s.taxRate.toStringAsFixed(0)}% GST", style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(CurrencyFormatter.format(s.taxableAmount))),
                            DataCell(Text(CurrencyFormatter.format(s.cgstAmount))),
                            DataCell(Text(CurrencyFormatter.format(s.sgstAmount))),
                            DataCell(Text(CurrencyFormatter.format(s.totalTax), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ])),
                      // Total Row
                      DataRow(
                        cells: [
                          const DataCell(Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(CurrencyFormatter.format(gst.totalTaxableAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(CurrencyFormatter.format(gst.totalCgst), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(CurrencyFormatter.format(gst.totalSgst), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(CurrencyFormatter.format(gst.totalGst), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HSN Code Summary Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HSN / SAC Wise Sales Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (gst.hsnSummary.isEmpty)
                  const Text("No HSN summary data recorded.")
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("HSN / SAC Code")),
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Total Qty")),
                        DataColumn(label: Text("Taxable Value")),
                        DataColumn(label: Text("Total Tax")),
                        DataColumn(label: Text("Total Value")),
                      ],
                      rows: gst.hsnSummary.map((h) => DataRow(cells: [
                            DataCell(Text(h.hsnCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(h.description)),
                            DataCell(Text("${h.totalQuantity}")),
                            DataCell(Text(CurrencyFormatter.format(h.taxableAmount))),
                            DataCell(Text(CurrencyFormatter.format(h.totalTax))),
                            DataCell(Text(CurrencyFormatter.format(h.totalValue), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ])).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double width = 220,
  }) {
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  radius: 18,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
