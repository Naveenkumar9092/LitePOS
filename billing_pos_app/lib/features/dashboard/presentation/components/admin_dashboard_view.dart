import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/dashboard_state.dart";
import "package:billing_pos_app/features/users/presentation/widgets/create_cashier_dialog.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "payment_summary_card.dart";
import "sales_chart_widget.dart";
import "sales_summary_cards.dart";

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminDashboardProvider);

    return adminAsync.when(
      loading: () => const Center(
        child: AppLoader(message: "Loading Admin Dashboard..."),
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
        final isMobile = constraints.maxWidth < 650;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(adminDashboardProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 22,
              vertical: isMobile ? 14 : 20,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterBar(context, ref, isMobile),
              const SizedBox(height: 16),
              _buildAdminQuickActions(context),
              const SizedBox(height: 18),
              SalesSummaryCards(summary: data.salesSummary),
              const SizedBox(height: 18),
              _buildSecondaryStats(context, data),
              const SizedBox(height: 18),

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
                      child: PaymentSummaryCard(summary: data.paymentSummary),
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
                    const SizedBox(height: 18),
                    PaymentSummaryCard(summary: data.paymentSummary),
                    const SizedBox(height: 18),
                    _buildCashierBreakdownCard(context, data.cashierBreakdown),
                  ],
                ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, bool isMobile) {
    final selectedDate = ref.watch(dashboardDateFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "Store Intelligence Hub",
                    style: GoogleFonts.dmSans(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: isDark ? 0.45 : 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "LIVE POS",
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
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
              "Real-time revenue velocity, settlement splits & registers",
              style: GoogleFonts.dmSans(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: isMobile ? 11.5 : 13,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                    const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.neonCyan),
                    const SizedBox(width: 6),
                    Text(
                      selectedDate == null
                          ? "Today"
                          : "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedDate != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: "Reset to Today",
                onPressed: () {
                  ref.read(dashboardDateFilterProvider.notifier).state = null;
                },
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: "Refresh Metrics",
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
              },
            ),
            const SizedBox(width: 8),
            // Fast POS Billing Action Button
            ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.posBilling),
              icon: const Icon(Icons.point_of_sale_rounded, size: 16),
              label: Text("New Sale", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonCyan,
      glowOpacity: isDark ? 0.12 : 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.neonCyan, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Store Administration Operations",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // Create Cashier Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CreateCashierDialog(),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text("Create Cashier", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
              ),

              // Store & Outlet Profile
              OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.companyProfile),
                icon: const Icon(Icons.storefront_rounded, size: 16, color: AppColors.neonCyan),
                label: Text("Store & Outlet Profile", style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isDark ? AppColors.neonCyan.withValues(alpha: 0.5) : AppColors.outlineLight,
                  ),
                ),
              ),

              // Menu & Catalog
              OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.products),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 16, color: AppColors.neonAmber),
                label: Text("Menu Catalog", style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isDark ? AppColors.neonAmber.withValues(alpha: 0.5) : AppColors.outlineLight,
                  ),
                ),
              ),

              // Orders & Invoices
              OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.orders),
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.neonBlue),
                label: Text("Order History", style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isDark ? AppColors.neonBlue.withValues(alpha: 0.5) : AppColors.outlineLight,
                  ),
                ),
              ),

              // Reports & Softcopy
              OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.reports),
                icon: const Icon(Icons.analytics_rounded, size: 16, color: AppColors.neonViolet),
                label: Text("Reports & Softcopy", style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isDark ? AppColors.neonViolet.withValues(alpha: 0.5) : AppColors.outlineLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(BuildContext context, AdminDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double itemWidth;
        final double spacing;

        if (w >= 900) {
          itemWidth = (w - 32) / 3;
          spacing = 16;
        } else if (w >= 540) {
          itemWidth = (w - 14) / 2;
          spacing = 14;
        } else {
          itemWidth = w;
          spacing = 10;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: neonColor.withValues(alpha: isDark ? 0.40 : 0.25),
              ),
            ),
            child: Icon(icon, color: neonColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(18),
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
              Flexible(
                child: Text(
                  "Cashier Staff Performance & Shift Billed",
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
