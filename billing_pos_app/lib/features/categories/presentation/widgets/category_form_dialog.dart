import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";
import "package:billing_pos_app/features/categories/presentation/category_state.dart";

class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _orderController;
  late bool _isActive;
  bool _isSubmitting = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.categoryName ?? "");
    _descController = TextEditingController(text: widget.category?.description ?? "");
    _orderController = TextEditingController(
      text: widget.category != null ? widget.category!.displayOrder.toString() : "0",
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();
    final order = int.tryParse(_orderController.text.trim()) ?? 0;

    setState(() => _isSubmitting = true);
    bool success = false;
    try {
      final notifier = ref.read(categoryNotifierProvider.notifier);

      if (_isEditing) {
        success = await notifier.updateCategory(
          widget.category!.categoryId,
          name: name,
          description: desc,
          imageKey: widget.category!.categoryImageStorageKey,
          displayOrder: order,
          isActive: _isActive,
        );
      } else {
        success = await notifier.createCategory(
          name: name,
          description: desc,
          displayOrder: order,
        );
      }

      if (mounted && success) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
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
                      _isEditing ? "Edit Category" : "Add New Category",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Category Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Category Name *",
                    hintText: "e.g., Beverages, Desserts, Coffee",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Category name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Short description of the category...",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 500,
                ),
                const SizedBox(height: 12),
                // Display Order
                TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: "Display Order",
                    hintText: "0 = Auto assign next order",
                    prefixIcon: Icon(Icons.sort),
                    border: OutlineInputBorder(),
                    helperText: "Lower numbers appear first in the POS catalog",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed < 0) {
                        return "Please enter a valid positive number";
                      }
                    }
                    return null;
                  },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Active Status"),
                    subtitle: Text(_isActive ? "Category is active and visible" : "Category is hidden"),
                    value: _isActive,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: _isEditing ? "Update Category" : "Create Category",
                      icon: _isEditing ? Icons.save : Icons.add,
                      isLoading: _isSubmitting,
                      onPressed: _handleSave,
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
