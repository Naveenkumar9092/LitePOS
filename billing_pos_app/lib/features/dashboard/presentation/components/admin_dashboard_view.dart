import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/dashboard_state.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";
import "payment_summary_card.dart";
import "recent_transactions_widget.dart";
import "sales_chart_widget.dart";
import "sales_summary_cards.dart";

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminDashboardProvider);

    return adminAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              "Failed to load Admin dashboard: $err",
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminDashboardProvider),
              child: Text("Retry", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      data: (data) => _buildContent(context, data, ref),
    );
  }

  Widget _buildContent(BuildContext context, AdminDashboardModel data, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 950;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterBar(context, ref),
              const SizedBox(height: 20),
              SalesSummaryCards(summary: data.salesSummary),
              const SizedBox(height: 20),
              _buildSecondaryStats(context, data),
              const SizedBox(height: 20),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          SalesChartWidget(
                            dailyPoints: data.dailySalesTrend,
                            monthlyPoints: data.monthlySalesTrend,
                          ),
                          const SizedBox(height: 20),
                          _buildCashierBreakdownCard(context, data.cashierBreakdown),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          PaymentSummaryCard(summary: data.paymentSummary),
                          const SizedBox(height: 20),
                          RecentTransactionsWidget(
                            transactions: data.recentInvoices,
                            onViewAll: () => context.go(RouteNames.orders),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SalesChartWidget(
                      dailyPoints: data.dailySalesTrend,
                      monthlyPoints: data.monthlySalesTrend,
                    ),
                    const SizedBox(height: 20),
                    PaymentSummaryCard(summary: data.paymentSummary),
                    const SizedBox(height: 20),
                    _buildCashierBreakdownCard(context, data.cashierBreakdown),
                    const SizedBox(height: 20),
                    RecentTransactionsWidget(
                      transactions: data.recentInvoices,
                      onViewAll: () => context.go(RouteNames.orders),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(dashboardDateFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Store Intelligence Hub",
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "LIVE POS",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "Real-time telemetry of revenue velocity, settlement splits & registers",
              style: GoogleFonts.dmSans(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(dashboardDateFilterProvider.notifier).state = picked;
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.outlineLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.neonCyan),
                    const SizedBox(width: 8),
                    Text(
                      selectedDate == null
                          ? "Today"
                          : "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedDate != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: "Reset to Today",
                onPressed: () {
                  ref.read(dashboardDateFilterProvider.notifier).state = null;
                },
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: "Refresh Metrics",
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
              },
            ),
            const SizedBox(width: 8),
            // Fast POS Billing Action Button
            ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.posBilling),
              icon: const Icon(Icons.point_of_sale_rounded, size: 18),
              label: Text("New Sale", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryStats(BuildContext context, AdminDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final itemWidth = isNarrow ? (constraints.maxWidth - 8) / 2 : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildSecondaryCard(
                context: context,
                title: "Customers Served",
                value: "${data.totalCustomers}",
                icon: Icons.people_alt_rounded,
                neonColor: AppColors.neonBlue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildSecondaryCard(
                context: context,
                title: "Completed Invoices",
                value: "${data.completedOrders}",
                icon: Icons.check_circle_rounded,
                neonColor: AppColors.neonEmerald,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildSecondaryCard(
                context: context,
                title: "Cancelled / Voids",
                value: "${data.cancelledOrders}",
                icon: Icons.cancel_rounded,
                neonColor: AppColors.neonCoral,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color neonColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 14,
      glowColor: neonColor,
      glowOpacity: isDark ? 0.10 : 0.04,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: neonColor.withValues(alpha: isDark ? 0.40 : 0.25),
              ),
            ),
            child: Icon(icon, color: neonColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashierBreakdownCard(BuildContext context, List<CashierSalesModel> cashiers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonViolet,
      glowOpacity: isDark ? 0.10 : 0.04,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.neonViolet,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonViolet.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Cashier Staff Performance & Shift Billed",
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (cashiers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  "No cashier transactions recorded for this period",
                  style: GoogleFonts.dmSans(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                ),
                columns: [
                  DataColumn(label: Text("Cashier", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Invoices", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  DataColumn(label: Text("Cash", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  DataColumn(label: Text("UPI", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  DataColumn(label: Text("Card", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  DataColumn(label: Text("Total Collection", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
                rows: cashiers.map((c) {
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.neonViolet.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, size: 14, color: AppColors.neonViolet),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.cashierName,
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                          ),
                        ],
                      )),
                      DataCell(Text("${c.invoiceCount}", style: GoogleFonts.dmSans())),
                      DataCell(Text(CurrencyFormatter.format(c.cashCollected), style: GoogleFonts.dmSans())),
                      DataCell(Text(CurrencyFormatter.format(c.upiCollected), style: GoogleFonts.dmSans())),
                      DataCell(Text(CurrencyFormatter.format(c.cardCollected), style: GoogleFonts.dmSans())),
                      DataCell(Text(
                        CurrencyFormatter.format(c.totalSales),
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.neonCyan : AppColors.primary,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
