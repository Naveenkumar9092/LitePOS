import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";

class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummaryModel summary;

  const PaymentSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grandTotal = summary.grandTotal > 0 ? summary.grandTotal : 1.0;
    final cashPct = (summary.cashTotal / grandTotal).clamp(0.0, 1.0);
    final upiPct = (summary.upiTotal / grandTotal).clamp(0.0, 1.0);
    final cardPct = (summary.cardTotal / grandTotal).clamp(0.0, 1.0);

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonEmerald,
      glowOpacity: isDark ? 0.12 : 0.05,
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
                    "Payment Breakdown",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonEmerald.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neonEmerald.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  CurrencyFormatter.format(summary.grandTotal),
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.neonEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Glowing Multi-Segment Neon Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  if (cashPct > 0)
                    Expanded(
                      flex: (cashPct * 1000).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.neonEmerald,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonEmerald.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (upiPct > 0)
                    Expanded(
                      flex: (upiPct * 1000).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.neonViolet,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonViolet.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (cardPct > 0)
                    Expanded(
                      flex: (cardPct * 1000).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (summary.grandTotal == 0)
                    Expanded(
                      child: Container(color: Colors.grey.shade400.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          _buildPaymentRow(
            context: context,
            label: "Cash",
            amount: summary.cashTotal,
            txCount: summary.cashTransactions,
            percentage: (cashPct * 100).toStringAsFixed(1),
            neonColor: AppColors.neonEmerald,
            icon: Icons.payments_outlined,
          ),
          Divider(
            height: 22,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
          _buildPaymentRow(
            context: context,
            label: "UPI / QR",
            amount: summary.upiTotal,
            txCount: summary.upiTransactions,
            percentage: (upiPct * 100).toStringAsFixed(1),
            neonColor: AppColors.neonViolet,
            icon: Icons.qr_code_2_rounded,
          ),
          Divider(
            height: 22,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
          _buildPaymentRow(
            context: context,
            label: "Card / POS Terminal",
            amount: summary.cardTotal,
            txCount: summary.cardTransactions,
            percentage: (cardPct * 100).toStringAsFixed(1),
            neonColor: AppColors.neonCyan,
            icon: Icons.credit_card_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required BuildContext context,
    required String label,
    required double amount,
    required int txCount,
    required String percentage,
    required Color neonColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: neonColor.withValues(alpha: isDark ? 0.40 : 0.30),
            ),
          ),
          child: Icon(icon, size: 18, color: neonColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$txCount transactions  •  $percentage%",
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
