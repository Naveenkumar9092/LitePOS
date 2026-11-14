import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../company/data/company_repository.dart";
import "../data/category_repository.dart";
import "../models/category_model.dart";

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepository(dioClient, db);
});

class CategoryState {
  final bool isLoading;
  final bool isSaving;
  final List<CategoryModel> categories;
  final String searchQuery;
  final bool? filterActive;
  final String? errorMessage;
  final String? successMessage;

  const CategoryState({
    this.isLoading = false,
    this.isSaving = false,
    this.categories = const [],
    this.searchQuery = "",
    this.filterActive,
    this.errorMessage,
    this.successMessage,
  });

  List<CategoryModel> get filteredCategories {
    return categories.where((c) {
      if (filterActive != null && c.isActive != filterActive) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = c.categoryName.toLowerCase().contains(query);
        final matchesDesc = c.description?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesDesc) return false;
      }
      return true;
    }).toList();
  }

  CategoryState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<CategoryModel>? categories,
    String? searchQuery,
    bool? filterActive,
    String? errorMessage,
    String? successMessage,
    bool clearFilterActive = false,
    bool clearMessages = false,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      filterActive: clearFilterActive ? null : (filterActive ?? this.filterActive),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const CategoryState()) {
    loadCategories();
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final categories = await _repository.getCategories(forceRefresh: forceRefresh);
      state = state.copyWith(
        isLoading: false,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to load categories: ${e.toString()}",
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterActive(bool? filterActive) {
    if (filterActive == null) {
      state = state.copyWith(clearFilterActive: true);
    } else {
      state = state.copyWith(filterActive: filterActive);
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
    String? imageKey,
    int displayOrder = 0,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final newCat = await _repository.createCategory(
        name: name,
        description: description,
        imageKey: imageKey,
        displayOrder: displayOrder,
      );

      final updatedList = [...state.categories, newCat]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      state = state.copyWith(
        isSaving: false,
        categories: updatedList,
        successMessage: "Category '${newCat.categoryName}' created successfully.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> updateCategory(
    int id, {
    required String name,
    String? description,
    String? imageKey,
    required int displayOrder,
    required bool isActive,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final updatedCat = await _repository.updateCategory(
        id,
        name: name,
        description: description,
        imageKey: imageKey,
        displayOrder: displayOrder,
        isActive: isActive,
      );

      final updatedList = state.categories.map((c) => c.categoryId == id ? updatedCat : c).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      state = state.copyWith(
        isSaving: false,
        categories: updatedList,
        successMessage: "Category '${updatedCat.categoryName}' updated successfully.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> toggleCategoryStatus(int id, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await _repository.updateCategoryStatus(id, newStatus);
      final updatedList = state.categories.map((c) {
        if (c.categoryId == id) {
          return c.copyWith(isActive: newStatus);
        }
        return c;
      }).toList();

      state = state.copyWith(
        categories: updatedList,
        successMessage: "Category status updated to ${newStatus ? 'Active' : 'Inactive'}.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  Future<void> reorderCategory(int oldIndex, int newIndex) async {
    final list = [...state.categories];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update display orders sequentially
    final sortItems = <Map<String, dynamic>>[];
    final updatedList = <CategoryModel>[];
    for (int i = 0; i < list.length; i++) {
      final updated = list[i].copyWith(displayOrder: i + 1);
      updatedList.add(updated);
      sortItems.add({
        "categoryId": updated.categoryId,
        "displayOrder": i + 1,
      });
    }

    state = state.copyWith(categories: updatedList);

    try {
      await _repository.updateSortOrder(sortItems);
    } catch (e) {
      state = state.copyWith(
        errorMessage: "Failed to persist new category order: ${e.toString().replaceFirst('Exception: ', '')}",
      );
    }
  }

  Future<bool> deleteCategory(int id) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _repository.deleteCategory(id);
      final updatedList = state.categories.where((c) => c.categoryId != id).toList();
      state = state.copyWith(
        isSaving: false,
        categories: updatedList,
        successMessage: "Category deleted successfully.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repo);
});

