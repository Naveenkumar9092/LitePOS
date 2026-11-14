import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";

class PaymentDialogResult {
  final double paidAmount;
  final int paymentMode; // 1 = Cash, 2 = UPI, 3 = Card
  final String? transactionReference;

  PaymentDialogResult({
    required this.paidAmount,
    required this.paymentMode,
    this.transactionReference,
  });
}

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({super.key, required this.totalAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  int _selectedMode = 1; // 1 = Cash, 2 = UPI, 3 = Card
  late TextEditingController _amountController;
  final TextEditingController _refController = TextEditingController();
  double _receivedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _receivedAmount = widget.totalAmount;
    _amountController = TextEditingController(text: widget.totalAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    setState(() {
      _receivedAmount = double.tryParse(val) ?? 0.0;
    });
  }

  void _setPresetAmount(double amount) {
    setState(() {
      _receivedAmount = amount;
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  double get _changeDue => (_receivedAmount - widget.totalAmount) > 0 ? (_receivedAmount - widget.totalAmount) : 0.0;

  @override
  Widget build(BuildContext context) {
    final quickCashOptions = {
      widget.totalAmount,
      (widget.totalAmount / 100).ceil() * 100.0,
      (widget.totalAmount / 500).ceil() * 500.0,
      2000.0,
    }.where((a) => a >= widget.totalAmount).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payment, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("Payment & Settlement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Total Payable Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text("TOTAL PAYABLE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatINR(widget.totalAmount),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Mode Selector Tabs
              Row(
                children: [
                  Expanded(
                    child: _buildModeTab(1, "Cash", Icons.money),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeTab(2, "UPI / QR", Icons.qr_code_2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeTab(3, "Card", Icons.credit_card),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Specific Options
              if (_selectedMode == 1) ...[
                const Text("Quick Cash Presets", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickCashOptions.map((amt) {
                    final isSelected = (_receivedAmount - amt).abs() < 0.01;
                    return ActionChip(
                      label: Text(amt == widget.totalAmount ? "Exact (${CurrencyFormatter.formatINR(amt)})" : CurrencyFormatter.formatINR(amt)),
                      backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                      onPressed: () => _setPresetAmount(amt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Amount Tendered & Change Due
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Cash Tendered",
                          prefixText: "₹ ",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onAmountChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _changeDue > 0 ? AppColors.successContainer.withValues(alpha: 0.3) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _changeDue > 0 ? AppColors.success : Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Change Due", style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatINR(_changeDue),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _changeDue > 0 ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _refController,
                  decoration: InputDecoration(
                    labelText: _selectedMode == 2 ? "UPI Reference / UTR Number (Optional)" : "Card Authorization Code (Optional)",
                    hintText: "e.g. 123456789012",
                    prefixIcon: Icon(_selectedMode == 2 ? Icons.receipt_long : Icons.pin),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  AppButton(
                    text: "Complete & Print Invoice",
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      Navigator.of(context).pop(PaymentDialogResult(
                        paidAmount: _receivedAmount,
                        paymentMode: _selectedMode,
                        transactionReference: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(int mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          if (mode != 1) {
            _receivedAmount = widget.totalAmount;
            _amountController.text = widget.totalAmount.toStringAsFixed(2);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textPrimary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
