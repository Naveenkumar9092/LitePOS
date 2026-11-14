import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";

class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummaryModel summary;

  const PaymentSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final grandTotal = summary.grandTotal > 0 ? summary.grandTotal : 1.0;
    final cashPct = (summary.cashTotal / grandTotal).clamp(0.0, 1.0);
    final upiPct = (summary.upiTotal / grandTotal).clamp(0.0, 1.0);
    final cardPct = (summary.cardTotal / grandTotal).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Payment Breakdown",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "Total: ${CurrencyFormatter.format(summary.grandTotal)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (cashPct > 0)
                    Expanded(
                      flex: (cashPct * 1000).toInt(),
                      child: Container(color: Colors.green),
                    ),
                  if (upiPct > 0)
                    Expanded(
                      flex: (upiPct * 1000).toInt(),
                      child: Container(color: Colors.blue),
                    ),
                  if (cardPct > 0)
                    Expanded(
                      flex: (cardPct * 1000).toInt(),
                      child: Container(color: Colors.deepPurple),
                    ),
                  if (summary.grandTotal == 0)
                    Expanded(
                      child: Container(color: Colors.grey.shade300),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            label: "Cash",
            amount: summary.cashTotal,
            txCount: summary.cashTransactions,
            percentage: (cashPct * 100).toStringAsFixed(1),
            color: Colors.green,
            icon: Icons.payments_outlined,
          ),
          const Divider(height: 20),
          _buildPaymentRow(
            label: "UPI / QR",
            amount: summary.upiTotal,
            txCount: summary.upiTransactions,
            percentage: (upiPct * 100).toStringAsFixed(1),
            color: Colors.blue,
            icon: Icons.qr_code_2,
          ),
          const Divider(height: 20),
          _buildPaymentRow(
            label: "Card / POS Terminal",
            amount: summary.cardTotal,
            txCount: summary.cardTransactions,
            percentage: (cardPct * 100).toStringAsFixed(1),
            color: Colors.deepPurple,
            icon: Icons.credit_card,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required String label,
    required double amount,
    required int txCount,
    required String percentage,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                "$txCount txns  â€¢  $percentage%",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
