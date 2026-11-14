import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment & Settlement",
                          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          "Pooja Sweets & Cafe Billing Checkout",
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // Total Payable Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEBF4F6), Color(0xFFD4EFF1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCCE4E9), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      "TOTAL PAYABLE",
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatINR(widget.totalAmount),
                      style: GoogleFonts.dmSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Mode Selector Tabs
              Row(
                children: [
                  Expanded(
                    child: _buildModeTab(1, "Cash", Icons.payments_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeTab(2, "UPI / QR", Icons.qr_code_2_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeTab(3, "Card", Icons.credit_card_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Specific Options
              if (_selectedMode == 1) ...[
                Text(
                  "Quick Cash Presets",
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickCashOptions.map((amt) {
                    final isSelected = (_receivedAmount - amt).abs() < 0.01;
                    return ActionChip(
                      label: Text(
                        amt == widget.totalAmount ? "Exact (${CurrencyFormatter.formatINR(amt)})" : CurrencyFormatter.formatINR(amt),
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                      side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Cash Tendered",
                          labelStyle: GoogleFonts.dmSans(),
                          prefixText: "₹ ",
                          prefixStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: _onAmountChanged,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _changeDue > 0 ? const Color(0xFFD1FAE5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _changeDue > 0 ? AppColors.success : const Color(0xFFE2E8F0),
                            width: _changeDue > 0 ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Change Due",
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: _changeDue > 0 ? AppColors.success : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatINR(_changeDue),
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _changeDue > 0 ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedMode == 2) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Customer Dynamic QR Code", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              "Ask customer to scan using GPay, PhonePe, Paytm or BHIM UPI.",
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _refController,
                  style: GoogleFonts.dmSans(),
                  decoration: InputDecoration(
                    labelText: "UPI Reference / UTR Number (Optional)",
                    labelStyle: GoogleFonts.dmSans(),
                    hintText: "e.g. 123456789012",
                    hintStyle: GoogleFonts.dmSans(color: Colors.grey),
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.credit_card_rounded, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Card Swipe / Tap Terminal", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              "Process Visa, MasterCard, RuPay on counter EDC terminal.",
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _refController,
                  style: GoogleFonts.dmSans(),
                  decoration: InputDecoration(
                    labelText: "Card Authorization Code (Optional)",
                    labelStyle: GoogleFonts.dmSans(),
                    hintText: "e.g. 123456",
                    hintStyle: GoogleFonts.dmSans(color: Colors.grey),
                    prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cancel", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textPrimary, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
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
