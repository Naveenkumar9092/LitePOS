import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";

class RecentTransactionsWidget extends StatelessWidget {
  final List<RecentTransactionModel> transactions;
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Invoices",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text("View All Orders"),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  "No recent transactions yet today",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                    child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        tx.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentModeBadge(tx.paymentMode),
                    ],
                  ),
                  subtitle: Text(
                    "${tx.customerName}  â€¢  By ${tx.cashierName.isEmpty ? 'Cashier' : tx.cashierName}  â€¢  ${DateFormatter.formatRelative(tx.createdAt)}",
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(tx.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StatusBadge(
                        label: tx.invoiceStatus.toUpperCase(),
                        type: tx.invoiceStatus.toLowerCase() == "cancelled"
                            ? BadgeType.error
                            : BadgeType.success,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeBadge(String mode) {
    Color bg;
    Color fg;
    final lower = mode.toLowerCase();
    if (lower.contains("cash")) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green.shade800;
    } else if (lower.contains("upi")) {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blue.shade800;
    } else if (lower.contains("card")) {
      bg = Colors.deepPurple.withValues(alpha: 0.15);
      fg = Colors.deepPurple.shade800;
    } else {
      bg = Colors.grey.withValues(alpha: 0.15);
      fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
