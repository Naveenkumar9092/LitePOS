import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "../../models/gst_models.dart";
import "../gst_state.dart";

class TaxFormDialog extends ConsumerStatefulWidget {
  final TaxModel? tax;

  const TaxFormDialog({super.key, this.tax});

  @override
  ConsumerState<TaxFormDialog> createState() => _TaxFormDialogState();
}

class _TaxFormDialogState extends ConsumerState<TaxFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late bool _isDefault;
  late bool _isTaxInclusiveDefault;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tax?.taxName ?? "");
    _rateController = TextEditingController(text: widget.tax != null ? widget.tax!.ratePercentage.toStringAsFixed(1) : "");
    _isDefault = widget.tax?.isDefault ?? false;
    _isTaxInclusiveDefault = widget.tax?.isTaxInclusiveDefault ?? true;
    _isActive = widget.tax?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tax != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Tax Slab" : "Create Tax Slab",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Tax Slab Name *",
                    hintText: "e.g. GST 5%, GST 18%",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Tax name is required." : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Rate Percentage (%) *",
                    hintText: "e.g. 5.0, 18.0",
                    suffixText: "%",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Rate percentage is required.";
                    final val = double.tryParse(v);
                    if (val == null || val < 0 || val > 100) return "Enter valid rate between 0 and 100.";
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Default Tax Slab", style: TextStyle(fontSize: 14)),
                  subtitle: const Text("Automatically applied to new products", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Prices Are Tax-Inclusive", style: TextStyle(fontSize: 14)),
                  subtitle: const Text("Product selling price already includes GST", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _isTaxInclusiveDefault,
                  onChanged: (v) => setState(() => _isTaxInclusiveDefault = v),
                ),
                if (isEditing)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Active Status", style: TextStyle(fontSize: 14)),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _isSubmitting = true);
                                final req = CreateTaxRequest(
                                  taxName: _nameController.text.trim(),
                                  ratePercentage: double.parse(_rateController.text.trim()),
                                  isDefault: _isDefault,
                                  isTaxInclusiveDefault: _isTaxInclusiveDefault,
                                );

                                final ok = await ref.read(gstNotifierProvider.notifier).saveTax(
                                      req,
                                      id: widget.tax?.id,
                                      isActive: _isActive,
                                    );
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                                if (ok && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? "Save Changes" : "Create Tax"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
