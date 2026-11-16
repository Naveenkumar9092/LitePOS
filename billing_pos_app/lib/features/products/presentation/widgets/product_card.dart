import "package:flutter/material.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;
  final ValueChanged<bool>? onAvailabilityChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const ProductCard({
    super.key,
    required this.product,
    this.isAdmin = false,
    this.onAvailabilityChanged,
    this.onEdit,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Badge + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.categoryName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: product.isAvailable ? "AVAILABLE" : "OUT OF STOCK",
                type: product.isAvailable ? BadgeType.success : BadgeType.error,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Image Banner / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: _buildProductImage(product.productImageStorageKey),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            product.productName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              product.description!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PRICE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: product.isAvailable,
                    activeColor: AppColors.primary,
                    onChanged: onAvailabilityChanged,
                  ),
                  if (isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: "Edit Product",
                      onPressed: onEdit,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (product.taxPercentage > 0 || (product.hsnCode != null && product.hsnCode!.isNotEmpty)) ...[
            const SizedBox(height: 4),
            Text(
              "GST ${product.taxPercentage.toStringAsFixed(0)}%${product.hsnCode != null && product.hsnCode!.isNotEmpty ? '  •  HSN: ${product.hsnCode}' : ''}",
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImage(String? keyOrUrl) {
    if (keyOrUrl != null && keyOrUrl.isNotEmpty) {
      final url = keyOrUrl.startsWith("http")
          ? keyOrUrl
          : "${ApiEndpoints.baseUrl.replaceAll("/api/v1", "")}$keyOrUrl";
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        size: 36,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }
}
