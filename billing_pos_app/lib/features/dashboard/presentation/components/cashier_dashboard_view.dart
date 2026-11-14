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
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "recent_transactions_widget.dart";
import "shift_summary_card.dart";

class CashierDashboardView extends ConsumerWidget {
  const CashierDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashierAsync = ref.watch(cashierDashboardProvider);

    return cashierAsync.when(
      loading: () => const Center(
        child: AppLoader(message: "Loading Cashier Dashboard..."),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              "Failed to load Cashier dashboard: $err",
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(cashierDashboardProvider),
              child: Text("Retry", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      data: (data) => _buildContent(context, data, ref),
    );
  }

  Widget _buildContent(BuildContext context, CashierDashboardModel data, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionHeader(context, data),
              const SizedBox(height: 20),
              _buildQuickMetrics(context, data),
              const SizedBox(height: 20),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildPaymentCollectionCard(context, data),
                          const SizedBox(height: 20),
                          RecentTransactionsWidget(
                            transactions: data.recentTransactions,
                            onViewAll: () => context.go(RouteNames.orders),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: ShiftSummaryCard(shift: data.shiftSummary),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildPaymentCollectionCard(context, data),
                    const SizedBox(height: 20),
                    ShiftSummaryCard(shift: data.shiftSummary),
                    const SizedBox(height: 20),
                    RecentTransactionsWidget(
                      transactions: data.recentTransactions,
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

  Widget _buildActionHeader(BuildContext context, CashierDashboardModel data) {
    return GlassCard(
      borderRadius: 20,
      glowColor: AppColors.neonCyan,
      glowOpacity: 0.16,
      gradient: const LinearGradient(
        colors: [
          AppColors.primary,
          Color(0xFF063A4B),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Welcome back, ${data.cashierName}!",
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      "COUNTER READY",
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "High-speed counter billing, token issuance & offline sync active",
                style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: Text(
              "START NEW BILL",
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            onPressed: () {
              context.go(RouteNames.posBilling);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetrics(BuildContext context, CashierDashboardModel data) {
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
              child: _buildMetricTile(
                context: context,
                title: "My Sales Today",
                value: CurrencyFormatter.format(data.todaySales),
                icon: Icons.currency_rupee,
                neonColor: AppColors.neonEmerald,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "Invoices Generated",
                value: "${data.todayInvoices}",
                icon: Icons.receipt_long_rounded,
                neonColor: AppColors.neonBlue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "Held Cart Tickets",
                value: "${data.heldBillsCount}",
                icon: Icons.pause_circle_outline_rounded,
                neonColor: AppColors.neonAmber,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
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
      glowOpacity: isDark ? 0.12 : 0.05,
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

  Widget _buildPaymentCollectionCard(BuildContext context, CashierDashboardModel data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonEmerald,
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
                  color: AppColors.neonEmerald,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonEmerald.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "My Collection Channels Today",
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCollectionTile(
                  context: context,
                  title: "Cash In Hand",
                  amount: data.cashCollected,
                  icon: Icons.payments_outlined,
                  neonColor: AppColors.neonEmerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionTile(
                  context: context,
                  title: "UPI Received",
                  amount: data.upiCollected,
                  icon: Icons.qr_code_2_rounded,
                  neonColor: AppColors.neonViolet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionTile(
                  context: context,
                  title: "Card Swipes",
                  amount: data.cardCollected,
                  icon: Icons.credit_card_rounded,
                  neonColor: AppColors.neonCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTile({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color neonColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: neonColor.withValues(alpha: isDark ? 0.35 : 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: neonColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
