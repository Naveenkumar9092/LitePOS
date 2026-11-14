import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/payments/models/payment_models.dart";
import "package:billing_pos_app/features/payments/presentation/payment_state.dart";
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "widgets/close_register_dialog.dart";
import "widgets/open_register_dialog.dart";
import "widgets/refund_dialog.dart";

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends ConsumerState<PaymentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentStateProvider);
    final displayedPayments = state.displayedPayments;
    final recon = state.reconciliation;
    final isRegisterOpen = recon?.isRegisterOpen ?? false;

    ref.listen(paymentStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(paymentStateProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success),
        );
        ref.read(paymentStateProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  final statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRegisterOpen ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRegisterOpen ? Colors.green.shade400 : Colors.amber.shade400,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: isRegisterOpen ? Colors.green.shade700 : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRegisterOpen ? "Open" : "Closed",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRegisterOpen ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  );

                  final buttons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRegisterOpen)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.point_of_sale, size: 14),
                          label: const Text("Open Register", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => OpenRegisterDialog(
                                onConfirm: (float, notes) =>
                                    ref.read(paymentStateProvider.notifier).openRegister(float, notes: notes),
                              ),
                            );
                          },
                        )
                      else
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_clock, size: 14, color: Colors.orange),
                          label: const Text("Close Register", style: TextStyle(color: Colors.orange, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () {
                            final expected = recon?.expectedCashInDrawer ?? 0.0;
                            showDialog(
                              context: context,
                              builder: (ctx) => CloseRegisterDialog(
                                expectedCash: expected,
                                onConfirm: (actual, notes) =>
                                    ref.read(paymentStateProvider.notifier).closeRegister(actual, notes: notes),
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.assignment_return_outlined, size: 14, color: AppColors.error),
                        label: const Text("Refund", style: TextStyle(color: AppColors.error, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => RefundDialog(
                              onConfirm: (invId, amt, rsn) =>
                                  ref.read(paymentStateProvider.notifier).processRefund(invId, amt, rsn),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: "Refresh Payments",
                        onPressed: () => ref.read(paymentStateProvider.notifier).loadData(),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Payment Management",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            statusBadge,
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: buttons,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        "Payment Management",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      statusBadge,
                      const Spacer(),
                      buttons,
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Daily Reconciliation Metrics Summary
            if (recon != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth > 900 ? 160.0 : 130.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSummaryCard(
                            label: "Net Collected",
                            amount: recon.netCollected,
                            color: AppColors.primary,
                            icon: Icons.account_balance_wallet,
                            width: itemWidth + 20,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            label: "Cash Sales",
                            amount: recon.cashCollected,
                            color: Colors.green.shade700,
                            icon: Icons.payments,
                            width: itemWidth,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            label: "UPI Sales",
                            amount: recon.upiCollected,
                            color: Colors.purple.shade700,
                            icon: Icons.qr_code_2,
                            width: itemWidth,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            label: "Card Sales",
                            amount: recon.cardCollected,
                            color: Colors.blue.shade700,
                            icon: Icons.credit_card,
                            width: itemWidth,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            label: "Total Refunds",
                            amount: recon.totalRefunds,
                            color: AppColors.error,
                            icon: Icons.replay,
                            width: itemWidth,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            label: "Cash in Drawer",
                            amount: recon.expectedCashInDrawer,
                            color: Colors.orange.shade800,
                            icon: Icons.point_of_sale,
                            width: itemWidth + 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],

            // Filters & Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 750;
                  final searchField = TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search payments by invoice #, ref, customer...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(paymentStateProvider.notifier).setSearchQuery("");
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) {
                      ref.read(paymentStateProvider.notifier).setSearchQuery(val);
                    },
                  );

                  final filterChips = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          label: const Text("All Modes"),
                          selected: state.filterMode == null,
                          onSelected: (selected) {
                            if (selected) ref.read(paymentStateProvider.notifier).setFilterMode(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.payments, size: 16),
                          label: const Text("Cash"),
                          selected: state.filterMode == PaymentModeEnum.cash,
                          onSelected: (selected) {
                            ref.read(paymentStateProvider.notifier).setFilterMode(
                                  selected ? PaymentModeEnum.cash : null,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.qr_code_2, size: 16),
                          label: const Text("UPI"),
                          selected: state.filterMode == PaymentModeEnum.upi,
                          onSelected: (selected) {
                            ref.read(paymentStateProvider.notifier).setFilterMode(
                                  selected ? PaymentModeEnum.upi : null,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.credit_card, size: 16),
                          label: const Text("Card"),
                          selected: state.filterMode == PaymentModeEnum.card,
                          onSelected: (selected) {
                            ref.read(paymentStateProvider.notifier).setFilterMode(
                                  selected ? PaymentModeEnum.card : null,
                                );
                          },
                        ),
                      ],
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        filterChips,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 16),
                      filterChips,
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Transactions List
            Expanded(
              child: state.isLoading
                  ? const Center(child: AppLoader(message: "Loading Payments..."))
                  : displayedPayments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                "No payment transactions found",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Payments processed from POS billing and counter checkout will appear here.",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedPayments.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final payment = displayedPayments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatINR(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentTransactionModel payment) {
    final isRefund = payment.amount < 0 || payment.paymentStatus == PaymentStatusEnum.refunded;
    final modeColor = _getPaymentModeColor(payment.paymentMode);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Mode Icon Avatar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isRefund ? AppColors.error : modeColor).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRefund ? Icons.assignment_return : _getPaymentModeIcon(payment.paymentMode),
                color: isRefund ? AppColors.error : modeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        payment.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isRefund ? "Refund" : payment.paymentMode.label,
                          style: TextStyle(fontWeight: FontWeight.bold, color: modeColor, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Customer: ${payment.customerName ?? 'Walk-in Guest'} • ${DateFormatter.formatDateTime(payment.createdAt)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (payment.transactionReference != null && payment.transactionReference!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Ref: ${payment.transactionReference!}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: "monospace"),
                    ),
                  ],
                ],
              ),
            ),

            // Amount & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isRefund
                      ? "-${CurrencyFormatter.formatINR(payment.amount.abs())}"
                      : CurrencyFormatter.formatINR(payment.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isRefund ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isRefund ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRefund ? "Refunded" : "Paid",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isRefund ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentModeColor(PaymentModeEnum mode) {
    switch (mode) {
      case PaymentModeEnum.cash:
        return Colors.green.shade700;
      case PaymentModeEnum.upi:
        return Colors.purple.shade700;
      case PaymentModeEnum.card:
        return Colors.blue.shade700;
      case PaymentModeEnum.split:
        return Colors.orange.shade800;
    }
  }

  IconData _getPaymentModeIcon(PaymentModeEnum mode) {
    switch (mode) {
      case PaymentModeEnum.cash:
        return Icons.payments;
      case PaymentModeEnum.upi:
        return Icons.qr_code_2;
      case PaymentModeEnum.card:
        return Icons.credit_card;
      case PaymentModeEnum.split:
        return Icons.call_split;
    }
  }
}

