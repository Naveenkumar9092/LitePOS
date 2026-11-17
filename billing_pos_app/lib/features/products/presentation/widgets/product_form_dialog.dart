import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/shared/widgets/app_image_upload_picker.dart";
import "package:billing_pos_app/shared/widgets/app_text_field.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";
import "../product_state.dart";

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _hsnController;
  late TextEditingController _taxController;
  late TextEditingController _imageUrlController;

  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.productName ?? "");
    _priceController = TextEditingController(text: p != null ? p.sellingPrice.toString() : "");
    _descController = TextEditingController(text: p?.description ?? "");
    _hsnController = TextEditingController(text: p?.hsnCode ?? "");
    _taxController = TextEditingController(text: p != null ? p.taxPercentage.toString() : "5.0");
    _imageUrlController = TextEditingController(text: p?.productImageStorageKey ?? "");
    _selectedCategoryId = p?.categoryId;
    _isAvailable = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _hsnController.dispose();
    _taxController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid category.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final tax = double.tryParse(_taxController.text.trim()) ?? 5.0;

    final categories = ref.read(categoriesProvider).asData?.value ?? [];
    final selectedCat = categories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == _selectedCategoryId,
      orElse: () => null,
    );

    final data = {
      "categoryId": _selectedCategoryId,
      "categoryName": selectedCat?.categoryName,
      "productName": _nameController.text.trim(),
      "description": _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      "productImageStorageKey": _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      "sellingPrice": price,
      "taxPercentage": tax,
      "hsnCode": _hsnController.text.trim().isEmpty ? null : _hsnController.text.trim(),
      "isAvailable": _isAvailable,
    };

    bool success;
    if (widget.product == null) {
      success = await ref.read(productListNotifierProvider.notifier).createProduct(data);
    } else {
      success = await ref.read(productListNotifierProvider.notifier).updateProduct(widget.product!.id, data);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.product != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Product" : "Register New Product",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "One product has one single selling price without variants or add-ons.",
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Dropdown
                        const Text("Category *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        categoriesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text("Failed to load categories"),
                          data: (categories) {
                            final exists = categories.any((c) => c.id == _selectedCategoryId);
                            final effectiveId = exists
                                ? _selectedCategoryId
                                : (categories.isNotEmpty ? categories.first.id : null);
                            if (_selectedCategoryId != effectiveId) {
                              _selectedCategoryId = effectiveId;
                            }

                            return DropdownButtonFormField<int>(
                              value: effectiveId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: categories.map((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat.id,
                                  child: Text(cat.categoryName),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoryId = val;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Product Name
                        AppTextField(
                          label: "Product Name *",
                          controller: _nameController,
                          hint: "e.g. Cappuccino, Veg Sandwich",
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Product name is required.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Selling Price & Tax
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: AppTextField(
                                label: "Selling Price (â‚¹) *",
                                controller: _priceController,
                                hint: "e.g. 120.00",
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Selling price is required.";
                                  }
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal <= 0) {
                                    return "Must be greater than 0.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                label: "GST Tax %",
                                controller: _taxController,
                                hint: "5.0",
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // HSN Code
                        AppTextField(
                          label: "HSN Code",
                          controller: _hsnController,
                          hint: "e.g. 0901, 1905",
                        ),
                        const SizedBox(height: 16),
                        // Product Image Upload
                        AppImageUploadPicker(
                          label: "Product Image",
                          hintText: "Upload image via Pozo API or edit URL",
                          initialImageUrl: _imageUrlController.text.trim().isNotEmpty
                              ? _imageUrlController.text.trim()
                              : null,
                          onImageUploaded: (url) {
                            setState(() {
                              _imageUrlController.text = url;
                            });
                          },
                          onImageRemoved: () {
                            setState(() {
                              _imageUrlController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Description
                        AppTextField(
                          label: "Description",
                          controller: _descController,
                          hint: "Brief ingredients or serving description",
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        // Availability Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Available for Billing", style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text("If disabled, items cannot be ordered in POS billing.", style: TextStyle(fontSize: 12)),
                          value: _isAvailable,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: isEditing ? "Save Changes" : "Create Product",
                      isLoading: _isSubmitting,
                      onPressed: _submit,
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
