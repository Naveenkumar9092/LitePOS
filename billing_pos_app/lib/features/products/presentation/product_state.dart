import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../authentication/presentation/auth_state.dart";
import "../../categories/presentation/category_state.dart";
import "../../company/data/company_repository.dart";
import "../data/product_repository.dart";
import "../models/product_model.dart";

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return ProductRepository(dioClient, db);
});

final categoriesProvider = Provider<AsyncValue<List<CategoryModel>>>((ref) {
  final categoryState = ref.watch(categoryNotifierProvider);
  if (categoryState.isLoading && categoryState.categories.isEmpty) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(categoryState.categories.where((c) => c.isActive).toList());
});

class ProductListState {
  final bool isLoading;
  final List<ProductModel> products;
  final int totalCount;
  final String searchQuery;
  final int? selectedCategoryId;
  final bool? selectedAvailability;
  final bool? selectedActiveStatus;
  final String? errorMessage;
  final String? successMessage;

  const ProductListState({
    this.isLoading = false,
    this.products = const [],
    this.totalCount = 0,
    this.searchQuery = "",
    this.selectedCategoryId,
    this.selectedAvailability,
    this.selectedActiveStatus,
    this.errorMessage,
    this.successMessage,
  });

  ProductListState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    int? totalCount,
    String? searchQuery,
    int? selectedCategoryId,
    bool? selectedAvailability,
    bool? selectedActiveStatus,
    String? errorMessage,
    String? successMessage,
    bool clearCategoryFilter = false,
    bool clearAvailabilityFilter = false,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedAvailability: clearAvailabilityFilter ? null : (selectedAvailability ?? this.selectedAvailability),
      selectedActiveStatus: selectedActiveStatus ?? this.selectedActiveStatus,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repository;
  final int? _companyId;

  ProductListNotifier(this._repository, {int? companyId})
      : _companyId = companyId,
        super(const ProductListState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final result = await _repository.getProducts(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryId: state.selectedCategoryId,
        isAvailable: state.selectedAvailability,
        isActive: state.selectedActiveStatus ?? true,
        companyId: _companyId,
      );

      state = state.copyWith(
        isLoading: false,
        products: result.items,
        totalCount: result.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void setCategoryFilter(int? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategoryFilter: categoryId == null || categoryId == 0,
    );
    loadProducts();
  }

  void setAvailabilityFilter(bool? isAvailable) {
    state = state.copyWith(
      selectedAvailability: isAvailable,
      clearAvailabilityFilter: isAvailable == null,
    );
    loadProducts();
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createProduct(data);
      state = state.copyWith(
        isLoading: false,
        successMessage: "Product added successfully",
      );
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateProduct(id, data);
      state = state.copyWith(
        isLoading: false,
        successMessage: "Product updated successfully",
      );
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> toggleAvailability(int id, bool isAvailable) async {
    try {
      final ok = await _repository.toggleAvailability(id, isAvailable);
      if (ok) {
        // Optimistic in-memory update
        final updated = state.products.map((p) {
          return p.id == id ? p.copyWith(isAvailable: isAvailable) : p;
        }).toList();

        state = state.copyWith(
          products: updated,
          successMessage: "Product availability set to ${isAvailable ? 'Available' : 'Unavailable'}",
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> toggleStatus(int id, bool isActive) async {
    try {
      final ok = await _repository.toggleStatus(id, isActive);
      if (ok) {
        await loadProducts();
        state = state.copyWith(
          successMessage: "Product status set to ${isActive ? 'Active' : 'Inactive'}",
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }
}

final productListNotifierProvider = StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);
  final user = auth.user;
  final companyId = (user != null && !user.isSAdmin) ? user.companyId : null;
  return ProductListNotifier(repo, companyId: companyId);
});

