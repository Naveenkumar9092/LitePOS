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
        final w = constraints.maxWidth;
        final int columns;
        final double spacing;

        if (w >= 900) {
          columns = 4;
          spacing = 16;
        } else if (w >= 540) {
          columns = 2;
          spacing = 14;
        } else if (w >= 360) {
          columns = 2;
          spacing = 10;
        } else {
          columns = 1;
          spacing = 10;
        }

        final cardWidth = (w - (spacing * (columns - 1))) / columns;
        final isCompact = cardWidth < 210;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
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
                isCompact: isCompact,
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
                isCompact: isCompact,
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
                isCompact: isCompact,
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
                isCompact: isCompact,
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
    required bool isCompact,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 16,
      glowColor: neonColor,
      glowOpacity: isDark ? 0.18 : 0.10,
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: isCompact ? 11.5 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(8),
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
                child: Icon(icon, size: isCompact ? 15 : 18, color: neonColor),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.dmSans(
                fontSize: isCompact ? 19 : 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          if (isCompact) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: neonColor.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: neonColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: GoogleFonts.dmSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: neonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ] else ...[
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
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
