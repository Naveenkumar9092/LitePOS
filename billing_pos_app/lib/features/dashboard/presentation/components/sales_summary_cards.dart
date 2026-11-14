import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";

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
                title: "Total Sales",
                value: CurrencyFormatter.format(summary.totalSales),
                subtitle: "${summary.totalInvoices} Invoices",
                icon: Icons.currency_rupee,
                iconColor: AppColors.primary,
                bgColor: AppColors.primaryContainer.withValues(alpha: 0.35),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: "Avg Bill Value",
                value: CurrencyFormatter.format(summary.averageBillValue),
                subtitle: "Per order average",
                icon: Icons.analytics_outlined,
                iconColor: Colors.blue,
                bgColor: Colors.blue.withValues(alpha: 0.08),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: "Tax Collected",
                value: CurrencyFormatter.format(summary.totalTax),
                subtitle: "GST Output Tax",
                icon: Icons.account_balance_outlined,
                iconColor: Colors.teal,
                bgColor: Colors.teal.withValues(alpha: 0.08),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: "Net Sales",
                value: CurrencyFormatter.format(summary.netSales),
                subtitle: summary.totalDiscount > 0
                    ? "Disc: ${CurrencyFormatter.format(summary.totalDiscount)}"
                    : "Zero Discount",
                icon: Icons.trending_up,
                iconColor: Colors.green,
                bgColor: Colors.green.withValues(alpha: 0.08),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return AppCard(
      backgroundColor: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
