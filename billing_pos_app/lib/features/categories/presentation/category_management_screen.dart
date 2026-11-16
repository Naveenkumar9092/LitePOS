import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/responsive_layout.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "package:billing_pos_app/features/categories/presentation/category_state.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";
import "package:billing_pos_app/features/categories/presentation/widgets/category_card.dart";
import "package:billing_pos_app/features/categories/presentation/widgets/category_form_dialog.dart";

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategoryForm([CategoryModel? category]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryFormDialog(category: category),
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text("Delete Category"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${category.categoryName}'?\n\n"
          "Note: If products are currently assigned to this category, it cannot be deleted. "
          "You should deactivate it instead.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.user?.isAdmin == true || authState.user?.isSAdmin == true;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    // Listen for messages
    ref.listen<CategoryState>(categoryNotifierProvider, (prev, next) {
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

    final categories = state.filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
            : Row(
                children: [
                  const Icon(Icons.category, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text("Category Management", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${state.categories.length} total",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.restaurant_menu),
              tooltip: "Products",
              onPressed: () => context.go(RouteNames.products),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Categories",
              onPressed: () => ref.read(categoryNotifierProvider.notifier).loadCategories(forceRefresh: true),
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 26),
                tooltip: "Add Category",
                onPressed: () => _openCategoryForm(),
              ),
          ] else ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text("Products"),
              onPressed: () => context.go(RouteNames.products),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Categories",
              onPressed: () => ref.read(categoryNotifierProvider.notifier).loadCategories(forceRefresh: true),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: AppButton(
                  text: "Add Category",
                  icon: Icons.add,
                  onPressed: () => _openCategoryForm(),
                ),
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
            color: Theme.of(context).cardColor,
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search categories...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(categoryNotifierProvider.notifier).setSearchQuery("");
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          ref.read(categoryNotifierProvider.notifier).setSearchQuery(val);
                        },
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text("All"),
                              selected: state.filterActive == null,
                              onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(null),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text("Active"),
                              selected: state.filterActive == true,
                              onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(true),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text("Inactive"),
                              selected: state.filterActive == false,
                              onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search categories...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(categoryNotifierProvider.notifier).setSearchQuery("");
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            ref.read(categoryNotifierProvider.notifier).setSearchQuery(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status Filter Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("All"),
                            selected: state.filterActive == null,
                            onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(null),
                          ),
                          ChoiceChip(
                            label: const Text("Active"),
                            selected: state.filterActive == true,
                            onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(true),
                          ),
                          ChoiceChip(
                            label: const Text("Inactive"),
                            selected: state.filterActive == false,
                            onSelected: (_) => ref.read(categoryNotifierProvider.notifier).setFilterActive(false),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),

          // Main Category List
          Expanded(
            child: state.isLoading && state.categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                    ? _buildEmptyState(context, isAdmin, state.searchQuery)
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(categoryNotifierProvider.notifier).loadCategories(forceRefresh: true),
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: categories.length,
                          buildDefaultDragHandles: false,
                          onReorder: (oldIdx, newIdx) {
                            if (isAdmin && state.searchQuery.isEmpty && state.filterActive == null) {
                              ref.read(categoryNotifierProvider.notifier).reorderCategory(oldIdx, newIdx);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Reordering is only enabled when viewing all categories without search filter."),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return _buildCategoryCard(cat, index, isAdmin, isDesktop);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAdmin, String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No Categories Found",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? "No categories match '$searchQuery'"
                : "Get started by adding your first product category.",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add First Category"),
              onPressed: () => _openCategoryForm(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel cat, int index, bool isAdmin, bool isDesktop) {
    return CategoryCard(
      key: ValueKey(cat.categoryId),
      category: cat,
      isAdmin: isAdmin,
      dragHandle: isAdmin
          ? ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.drag_indicator, color: Colors.grey),
              ),
            )
          : null,
      onToggleStatus: (val) {
        ref.read(categoryNotifierProvider.notifier).toggleCategoryStatus(cat.categoryId, cat.isActive);
      },
      onEdit: () => _openCategoryForm(cat),
      onDelete: () => _confirmDelete(cat),
    );
  }
}
