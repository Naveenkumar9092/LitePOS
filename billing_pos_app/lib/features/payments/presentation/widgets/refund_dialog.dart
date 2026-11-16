import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";

class RefundDialog extends StatefulWidget {
  final int? initialInvoiceId;
  final double? maxRefundAmount;
  final Future<bool> Function(int invoiceId, double amount, String reason) onConfirm;

  const RefundDialog({
    super.key,
    this.initialInvoiceId,
    this.maxRefundAmount,
    required this.onConfirm,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final TextEditingController _invoiceIdController;
  late final TextEditingController _amountController;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  final List<String> _quickReasons = [
    "Item returned / defective",
    "Customer cancelled order",
    "Billing correction / overcharge",
    "Service dissatisfaction",
  ];

  @override
  void initState() {
    super.initState();
    _invoiceIdController = TextEditingController(
      text: widget.initialInvoiceId != null ? widget.initialInvoiceId.toString() : "",
    );
    _amountController = TextEditingController(
      text: widget.maxRefundAmount != null ? widget.maxRefundAmount!.toStringAsFixed(2) : "",
    );
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    final invoiceId = int.tryParse(_invoiceIdController.text.trim());
    if (invoiceId == null || invoiceId <= 0) {
      setState(() => _errorText = "Please enter a valid Invoice ID.");
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorText = "Please enter a valid positive refund amount.");
      return;
    }

    if (widget.maxRefundAmount != null && amount > widget.maxRefundAmount!) {
      setState(() => _errorText = "Refund amount cannot exceed ₹${widget.maxRefundAmount!.toStringAsFixed(2)}.");
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = "Refund reason is mandatory.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final success = await widget.onConfirm(invoiceId, amount, reason);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorText = "Refund failed. Verify the invoice ID and paid amount.";
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_return_outlined, color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Process Customer Refund", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Authorizes and records a refund transaction", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

              if (widget.initialInvoiceId == null) ...[
                TextField(
                  controller: _invoiceIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Invoice ID *",
                    hintText: "Enter ID of the invoice to refund",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Refund Amount (₹) *",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              const Text("Quick Reason Selection:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReasons.map((r) {
                  final isSelected = _reasonController.text == r;
                  return ChoiceChip(
                    label: Text(r, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _reasonController.text = selected ? r : "";
                        _errorText = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _reasonController,
                maxLines: 2,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: "Reason for Refund *",
                  hintText: "Explain why this refund is being issued...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 16),

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
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Confirm & Process Refund"),
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

