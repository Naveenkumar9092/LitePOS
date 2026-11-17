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
        final isMobile = constraints.maxWidth < 650;

        return RefreshIndicator(
          color: AppColors.neonEmerald,
          onRefresh: () async {
            ref.invalidate(cashierDashboardProvider);
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
              _buildActionHeader(context, data, isMobile),
              const SizedBox(height: 18),
              _buildQuickMetrics(context, data),
              const SizedBox(height: 18),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildPaymentCollectionCard(context, data, isMobile),
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
                    _buildPaymentCollectionCard(context, data, isMobile),
                    const SizedBox(height: 18),
                    ShiftSummaryCard(shift: data.shiftSummary),
                  ],
                ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildActionHeader(BuildContext context, CashierDashboardModel data, bool isMobile) {
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
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Welcome back, ${data.cashierName}!",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        "COUNTER READY",
                        style: GoogleFonts.dmSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "High-speed counter billing & token issuance active",
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      "START NEW BILL",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    onPressed: () => context.go(RouteNames.posBilling),
                  ),
                ),
              ],
            )
          : Row(
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
                  onPressed: () => context.go(RouteNames.posBilling),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickMetrics(BuildContext context, CashierDashboardModel data) {
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
                title: "Hold Cart Tickets",
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

  Widget _buildPaymentCollectionCard(BuildContext context, CashierDashboardModel data, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final channels = [
      _CollectionItem(
        title: "Cash In Hand",
        amount: data.cashCollected,
        icon: Icons.payments_outlined,
        neonColor: AppColors.neonEmerald,
      ),
      _CollectionItem(
        title: "UPI Received",
        amount: data.upiCollected,
        icon: Icons.qr_code_2_rounded,
        neonColor: AppColors.neonViolet,
      ),
      _CollectionItem(
        title: "Card Swipes",
        amount: data.cardCollected,
        icon: Icons.credit_card_rounded,
        neonColor: AppColors.neonCyan,
      ),
    ];

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonEmerald,
      glowOpacity: isDark ? 0.10 : 0.04,
      padding: EdgeInsets.all(isMobile ? 14 : 20),
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
              Flexible(
                child: Text(
                  "My Collection Channels Today",
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                // Stack vertically on narrow mobile
                return Column(
                  children: channels
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildCollectionTile(
                              context: context,
                              title: item.title,
                              amount: item.amount,
                              icon: item.icon,
                              neonColor: item.neonColor,
                            ),
                          ))
                      .toList(),
                );
              }

              return Row(
                children: channels
                    .map((item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildCollectionTile(
                              context: context,
                              title: item.title,
                              amount: item.amount,
                              icon: item.icon,
                              neonColor: item.neonColor,
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
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
      padding: const EdgeInsets.all(10),
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
              Icon(icon, size: 15, color: neonColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              maxLines: 1,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionItem {
  final String title;
  final double amount;
  final IconData icon;
  final Color neonColor;

  const _CollectionItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.neonColor,
  });
}
