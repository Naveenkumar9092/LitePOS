import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "../../models/gst_models.dart";
import "../gst_state.dart";

class CreditNoteDialog extends ConsumerStatefulWidget {
  final int? initialInvoiceId;

  const CreditNoteDialog({super.key, this.initialInvoiceId});

  @override
  ConsumerState<CreditNoteDialog> createState() => _CreditNoteDialogState();
}

class _CreditNoteDialogState extends ConsumerState<CreditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceIdController;
  late TextEditingController _reasonController;
  late TextEditingController _productIdController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;

  String _noteType = "CreditNote";
  bool _isSubmitting = false;

  final List<String> _quickReasons = [
    "Sales Return / Returned item",
    "Customer dissatisfaction with food quality",
    "Post-sale promotional discount applied",
    "Correction of inadvertent overcharge",
    "Billing system error adjustment",
  ];

  @override
  void initState() {
    super.initState();
    _invoiceIdController = TextEditingController(text: widget.initialInvoiceId?.toString() ?? "");
    _reasonController = TextEditingController(text: _quickReasons.first);
    _productIdController = TextEditingController(text: "1");
    _quantityController = TextEditingController(text: "1");
    _unitPriceController = TextEditingController(text: "100");
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _reasonController.dispose();
    _productIdController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Issue ${_noteType == "DebitNote" ? "Debit Note" : "Credit Note"}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: "CreditNote", label: Text("Credit Note (Return/Discount)")),
                      ButtonSegment(value: "DebitNote", label: Text("Debit Note (Supplemental)")),
                    ],
                    selected: {_noteType},
                    onSelectionChanged: (set) => setState(() => _noteType = set.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _invoiceIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Invoice ID *",
                      hintText: "e.g. 1, 2",
                      prefixIcon: Icon(Icons.receipt_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Invoice ID is required.";
                      final id = int.tryParse(v);
                      if (id == null || id <= 0) return "Enter a valid numeric Invoice ID.";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text("Quick Reason Selection:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickReasons.map((r) {
                      final isSelected = _reasonController.text == r;
                      return ChoiceChip(
                        label: Text(r, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        onSelected: (sel) {
                          if (sel) setState(() => _reasonController.text = r);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Detailed Reason *",
                      hintText: "Specify the exact reason for accounting audit",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().length < 3 ? "Reason must be at least 3 characters." : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _productIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Product ID",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => int.tryParse(v ?? "") == null ? "Valid ID required" : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final q = int.tryParse(v ?? "");
                            if (q == null || q <= 0) return "Min 1";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: "Unit Price",
                            prefixText: "₹",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final p = double.tryParse(v ?? "");
                            if (p == null || p < 0) return "Valid price";
                            return null;
                          },
                        ),
                      ),
                    ],
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
                                  final req = CreateCreditNoteRequest(
                                    invoiceId: int.parse(_invoiceIdController.text.trim()),
                                    reason: _reasonController.text.trim(),
                                    noteType: _noteType,
                                    items: [
                                      CreateCreditNoteItemRequest(
                                        productId: int.parse(_productIdController.text.trim()),
                                        quantity: int.parse(_quantityController.text.trim()),
                                        unitPrice: double.parse(_unitPriceController.text.trim()),
                                        reason: _reasonController.text.trim(),
                                      ),
                                    ],
                                  );

                                  final ok = await ref.read(gstNotifierProvider.notifier).issueCreditNote(req);
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
                            : Text("Issue $_noteType"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
