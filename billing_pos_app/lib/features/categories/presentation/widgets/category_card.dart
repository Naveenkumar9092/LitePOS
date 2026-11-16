import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleStatus;
  final Widget? dragHandle;

  const CategoryCard({
    super.key,
    required this.category,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: category.isActive ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (dragHandle != null) dragHandle!,
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "#${category.displayOrder}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.categoryName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(
                        label: category.isActive ? "Active" : "Inactive",
                        type: category.isActive ? BadgeType.success : BadgeType.neutral,
                      ),
                    ],
                  ),
                  if (category.description != null && category.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      category.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "${category.productCount} ${category.productCount == 1 ? 'Product' : 'Products'}",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: category.isActive,
                              activeColor: AppColors.primary,
                              onChanged: onToggleStatus,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                              tooltip: "Edit Category",
                              onPressed: onEdit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              tooltip: "Delete Category",
                              onPressed: onDelete,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  // Drag handle (if provided)
                  if (dragHandle != null) dragHandle!,

                  // Display order badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "#${category.displayOrder}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Category Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.categoryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: category.isActive ? "Active" : "Inactive",
                              type: category.isActive ? BadgeType.success : BadgeType.neutral,
                            ),
                          ],
                        ),
                        if (category.description != null && category.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            category.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Product Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "${category.productCount} ${category.productCount == 1 ? 'Product' : 'Products'}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Active Toggle & Action buttons
                  if (isAdmin) ...[
                    Tooltip(
                      message: category.isActive ? "Deactivate Category" : "Activate Category",
                      child: Switch(
                        value: category.isActive,
                        activeColor: AppColors.primary,
                        onChanged: onToggleStatus,
                      ),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: "Edit Category",
                      onPressed: onEdit,
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: "Delete Category",
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
