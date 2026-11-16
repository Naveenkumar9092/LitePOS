import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "../../models/gst_models.dart";
import "../gst_state.dart";

class HsnFormDialog extends ConsumerStatefulWidget {
  final HsnSacModel? hsn;

  const HsnFormDialog({super.key, this.hsn});

  @override
  ConsumerState<HsnFormDialog> createState() => _HsnFormDialogState();
}

class _HsnFormDialogState extends ConsumerState<HsnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _descController;
  late TextEditingController _rateController;
  late String _type;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.hsn?.code ?? "");
    _descController = TextEditingController(text: widget.hsn?.description ?? "");
    _rateController = TextEditingController(text: widget.hsn != null ? widget.hsn!.defaultGstRate.toStringAsFixed(1) : "5.0");
    _type = widget.hsn?.type ?? "HSN";
    _isActive = widget.hsn?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.hsn != null;

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
                      isEditing ? "Edit HSN/SAC Code" : "Add HSN/SAC Code",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: "Code *",
                          hintText: "e.g. 2106, 9963",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? "Code required." : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "HSN", child: Text("HSN")),
                          DropdownMenuItem(value: "SAC", child: Text("SAC")),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? "HSN"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Description *",
                    hintText: "e.g. Food preparations, ice cream, beverages",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Description required." : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Default GST Rate (%) *",
                    suffixText: "%",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Rate required.";
                    final val = double.tryParse(v);
                    if (val == null || val < 0 || val > 100) return "Invalid rate.";
                    return null;
                  },
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
                                final req = CreateHsnRequest(
                                  code: _codeController.text.trim(),
                                  description: _descController.text.trim(),
                                  type: _type,
                                  defaultGstRate: double.parse(_rateController.text.trim()),
                                  isActive: _isActive,
                                );

                                final ok = await ref.read(gstNotifierProvider.notifier).saveHsn(req);
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
                          : Text(isEditing ? "Save Changes" : "Add HSN/SAC"),
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
