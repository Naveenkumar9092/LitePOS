import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "../../authentication/presentation/auth_state.dart";
import "product_state.dart";
import "widgets/product_card.dart";
import "widgets/product_form_dialog.dart";

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductForm([product]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.user?.isAdmin == true || authState.user?.isSAdmin == true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    // Listen for notifications
    ref.listen<ProductListState>(productListNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Text("Products & Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
            : const Row(
                children: [
                  Text("Product & Menu Management"),
                  SizedBox(width: 12),
                  StatusBadge(label: "SINGLE PRICE", type: BadgeType.info),
                ],
              ),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: "Categories",
              onPressed: () => context.go(RouteNames.categories),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Products",
              onPressed: () => ref.read(productListNotifierProvider.notifier).loadProducts(),
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 26),
                tooltip: "Add Product",
                onPressed: () => _openProductForm(),
              ),
          ] else ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.category, size: 18),
              label: const Text("Categories"),
              onPressed: () => context.go(RouteNames.categories),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Products",
              onPressed: () => ref.read(productListNotifierProvider.notifier).loadProducts(),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: AppButton(
                  text: "Add Product",
                  icon: Icons.add,
                  onPressed: () => _openProductForm(),
                ),
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(context, state, categoriesAsync),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.products.isEmpty
                    ? _buildEmptyState(context, isAdmin)
                    : _buildProductGrid(context, state, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context, ProductListState state, AsyncValue<List<dynamic>> categoriesAsync) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: isMobile ? "Search products or HSN..." : "Search products by name or HSN code...",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  ref.read(productListNotifierProvider.notifier).setSearchQuery("");
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        isDense: true,
      ),
      onChanged: (val) {
        ref.read(productListNotifierProvider.notifier).setSearchQuery(val);
      },
    );

    final statusSegment = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<bool?>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<bool?>(value: null, label: Text("All")),
          ButtonSegment<bool?>(value: true, label: Text("Available")),
          ButtonSegment<bool?>(value: false, label: Text("Out of Stock")),
        ],
        selected: {state.selectedAvailability},
        onSelectionChanged: (selection) {
          ref.read(productListNotifierProvider.notifier).setAvailabilityFilter(selection.first);
        },
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            searchField,
            const SizedBox(height: 8),
            statusSegment,
          ] else ...[
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 16),
                statusSegment,
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Category Filter Chips
          categoriesAsync.when(
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox(),
            data: (categories) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text("All Categories"),
                      selected: state.selectedCategoryId == null,
                      onSelected: (_) {
                        ref.read(productListNotifierProvider.notifier).setCategoryFilter(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) {
                      final isSelected = state.selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat.categoryName),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(productListNotifierProvider.notifier).setCategoryFilter(isSelected ? null : cat.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, ProductListState state, bool isAdmin) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final int crossAxisCount;
    final double childAspectRatio;

    if (screenWidth < 480) {
      crossAxisCount = 1;
      childAspectRatio = 1.25;
    } else if (screenWidth < 850) {
      crossAxisCount = 2;
      childAspectRatio = 0.72;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
      childAspectRatio = 0.80;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 0.88;
    }

    return GridView.builder(
      padding: EdgeInsets.all(screenWidth < 600 ? 12 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenWidth < 600 ? 10 : 16,
        mainAxisSpacing: screenWidth < 600 ? 10 : 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        return ProductCard(
          product: product,
          isAdmin: isAdmin,
          onAvailabilityChanged: (val) {
            ref.read(productListNotifierProvider.notifier).toggleAvailability(product.id, val);
          },
          onEdit: () => _openProductForm(product),
          onToggleStatus: () {
            ref.read(productListNotifierProvider.notifier).toggleStatus(product.id, !product.isActive);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAdmin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No Products Found",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try adjusting your search query or category filters.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Register First Product"),
              onPressed: () => _openProductForm(),
            ),
          ],
        ],
      ),
    );
  }
}
