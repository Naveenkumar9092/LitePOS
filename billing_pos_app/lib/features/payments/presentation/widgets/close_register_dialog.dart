import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";

class CloseRegisterDialog extends StatefulWidget {
  final double expectedCash;
  final Future<bool> Function(double actualCash, String? notes) onConfirm;

  const CloseRegisterDialog({
    super.key,
    required this.expectedCash,
    required this.onConfirm,
  });

  @override
  State<CloseRegisterDialog> createState() => _CloseRegisterDialogState();
}

class _CloseRegisterDialogState extends State<CloseRegisterDialog> {
  late final TextEditingController _actualCashController;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;
  double _discrepancy = 0.0;

  @override
  void initState() {
    super.initState();
    _actualCashController = TextEditingController(text: widget.expectedCash.toStringAsFixed(2));
    _discrepancy = 0.0;
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCashChanged(String val) {
    final parsed = double.tryParse(val.trim());
    if (parsed != null) {
      setState(() {
        _discrepancy = parsed - widget.expectedCash;
        _errorText = null;
      });
    }
  }

  void _submit() async {
    final actual = double.tryParse(_actualCashController.text.trim());
    if (actual == null || actual < 0) {
      setState(() {
        _errorText = "Please enter a valid non-negative cash amount.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final success = await widget.onConfirm(actual, _notesController.text.trim());
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorText = "Failed to close register. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Day Closing / Close Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Reconcile and lock the cash drawer", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Expected vs Counted Cash Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Expected Cash in Drawer:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                        Text(
                          CurrencyFormatter.formatINR(widget.expectedCash),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Difference:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                        Text(
                          _discrepancy == 0
                              ? "₹0.00 (Balanced)"
                              : (_discrepancy > 0
                                  ? "+${CurrencyFormatter.formatINR(_discrepancy)} (Overage)"
                                  : "-${CurrencyFormatter.formatINR(_discrepancy.abs())} (Shortage)"),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _discrepancy == 0
                                ? AppColors.success
                                : (_discrepancy > 0 ? Colors.blue.shade700 : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _actualCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onCashChanged,
                decoration: InputDecoration(
                  labelText: "Actual Counted Cash (₹) *",
                  prefixText: "₹ ",
                  errorText: _errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Closing Notes / Remarks",
                  hintText: "Enter any discrepancy explanation or shift notes...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Confirm & Close Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
