import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";

class OpenRegisterDialog extends StatefulWidget {
  final Future<bool> Function(double floatAmount, String? notes) onConfirm;

  const OpenRegisterDialog({super.key, required this.onConfirm});

  @override
  State<OpenRegisterDialog> createState() => _OpenRegisterDialogState();
}

class _OpenRegisterDialogState extends State<OpenRegisterDialog> {
  final TextEditingController _floatController = TextEditingController(text: "1000.00");
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  final List<double> _presetFloats = [500, 1000, 2000, 5000];

  @override
  void dispose() {
    _floatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final floatVal = double.tryParse(_floatController.text.trim());
    if (floatVal == null || floatVal < 0) {
      setState(() {
        _errorText = "Please enter a valid non-negative float amount.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final success = await widget.onConfirm(floatVal, _notesController.text.trim());
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorText = "Failed to open register. A session may already be open.";
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Day Opening / Open Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Set initial drawer cash float for this shift", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

              const Text("Quick Float Selection:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _presetFloats.map((val) {
                  final isSelected = double.tryParse(_floatController.text) == val;
                  return ChoiceChip(
                    label: Text("₹${val.toStringAsFixed(0)}"),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _floatController.text = val.toStringAsFixed(2);
                          _errorText = null;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _floatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Opening Float Amount (₹) *",
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
                  labelText: "Opening Notes (Optional)",
                  hintText: "e.g. 5x ₹100, 10x ₹50...",
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Open Cash Register"),
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

