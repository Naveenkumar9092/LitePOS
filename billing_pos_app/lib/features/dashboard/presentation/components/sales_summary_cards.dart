import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";

class SalesSummaryCards extends StatelessWidget {
  final SalesSummaryModel summary;

  const SalesSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context: context,
                title: "Total Sales",
                value: CurrencyFormatter.format(summary.totalSales),
                subtitle: "${summary.totalInvoices} Invoices",
                badgeText: "Gross Revenue",
                icon: Icons.currency_rupee,
                neonColor: AppColors.neonCyan,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context: context,
                title: "Avg Bill Value",
                value: CurrencyFormatter.format(summary.averageBillValue),
                subtitle: "Per order average",
                badgeText: "Ticket Size",
                icon: Icons.analytics_outlined,
                neonColor: AppColors.secondary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context: context,
                title: "Tax Collected",
                value: CurrencyFormatter.format(summary.totalTax),
                subtitle: "GST Output Tax",
                badgeText: "Tax Compliance",
                icon: Icons.account_balance_outlined,
                neonColor: AppColors.neonAmber,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context: context,
                title: "Net Sales",
                value: CurrencyFormatter.format(summary.netSales),
                subtitle: summary.totalDiscount > 0
                    ? "Disc: ${CurrencyFormatter.format(summary.totalDiscount)}"
                    : "Zero Discount",
                badgeText: "Net Earnings",
                icon: Icons.trending_up,
                neonColor: AppColors.neonEmerald,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color neonColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: neonColor,
      glowOpacity: isDark ? 0.18 : 0.10,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: neonColor.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: neonColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: neonColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: neonColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: neonColor,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: neonColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
