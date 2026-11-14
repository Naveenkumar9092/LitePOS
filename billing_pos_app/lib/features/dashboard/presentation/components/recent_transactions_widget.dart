import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonBlue,
      glowOpacity: isDark ? 0.10 : 0.04,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonBlue.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Recent Invoices",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    "View All Orders",
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0),
              child: Center(
                child: Text(
                  "No recent transactions yet today",
                  style: GoogleFonts.dmSans(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => Divider(
                height: 18,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: isDark ? AppColors.neonCyan : AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tx.invoiceNumber,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildPaymentModeBadge(tx.paymentMode, isDark),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${tx.customerName} • ${tx.cashierName.isEmpty ? 'Cashier' : tx.cashierName} • ${DateFormatter.formatRelative(tx.createdAt)}",
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(tx.totalAmount),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _buildStatusPill(tx.invoiceStatus, isDark),
                        ],
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

  Widget _buildPaymentModeBadge(String mode, bool isDark) {
    Color neonColor;
    final lower = mode.toLowerCase();
    if (lower.contains("cash")) {
      neonColor = AppColors.neonEmerald;
    } else if (lower.contains("upi")) {
      neonColor = AppColors.neonViolet;
    } else if (lower.contains("card")) {
      neonColor = AppColors.neonCyan;
    } else {
      neonColor = AppColors.neonAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: neonColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: neonColor.withValues(alpha: isDark ? 0.40 : 0.25),
        ),
      ),
      child: Text(
        mode.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: neonColor,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    final isCancelled = status.toLowerCase() == "cancelled";
    final color = isCancelled ? AppColors.error : AppColors.neonEmerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
