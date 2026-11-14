import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/dashboard_state.dart";
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text("Failed to load Admin dashboard: $err"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminDashboardProvider),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
      data: (data) => _buildContent(context, data, ref),
    );
  }

  Widget _buildContent(BuildContext context, AdminDashboardModel data, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(context, ref),
          const SizedBox(height: 16),
          SalesSummaryCards(summary: data.salesSummary),
          const SizedBox(height: 20),
          _buildSecondaryStats(context, data),
          const SizedBox(height: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(dashboardDateFilterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Executive Store Dashboard",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Text(
              "Real-time overview of sales, collections and cashier performance",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                selectedDate == null
                    ? "Today"
                    : "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
              ),
              onPressed: () async {
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
            ),
            if (selectedDate != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: "Reset to Today",
                onPressed: () {
                  ref.read(dashboardDateFilterProvider.notifier).state = null;
                },
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryStats(BuildContext context, AdminDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 32) / 3;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: const Icon(Icons.people_outline, color: Colors.blue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Customers", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text("${data.totalCustomers}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Completed Orders", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text("${data.completedOrders}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Cancelled Orders", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text("${data.cancelledOrders}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCashierBreakdownCard(BuildContext context, List<CashierSalesModel> cashiers) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cashier Performance & Collections",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (cashiers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text("No cashier billing recorded today")),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Cashier")),
                  DataColumn(label: Text("Bills", textAlign: TextAlign.right)),
                  DataColumn(label: Text("Cash", textAlign: TextAlign.right)),
                  DataColumn(label: Text("UPI", textAlign: TextAlign.right)),
                  DataColumn(label: Text("Card", textAlign: TextAlign.right)),
                  DataColumn(label: Text("Total Sales", textAlign: TextAlign.right)),
                ],
                rows: cashiers.map((c) {
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(c.cashierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      DataCell(Text("${c.invoiceCount}")),
                      DataCell(Text(CurrencyFormatter.format(c.cashCollected))),
                      DataCell(Text(CurrencyFormatter.format(c.upiCollected))),
                      DataCell(Text(CurrencyFormatter.format(c.cardCollected))),
                      DataCell(Text(
                        CurrencyFormatter.format(c.totalSales),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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
