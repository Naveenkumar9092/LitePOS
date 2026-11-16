import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";
import "package:billing_pos_app/features/categories/presentation/category_state.dart";

void main() {
  group("CategoryState Tests", () {
    final fixedDate = DateTime.utc(2026, 11, 13, 10, 0, 0);

    final cat1 = CategoryModel(
      categoryId: 1,
      categoryGuid: "guid-1",
      categoryName: "Coffee",
      description: "Espresso, lattes, cold brew",
      displayOrder: 1,
      isActive: true,
      productCount: 5,
      createdAtUtc: fixedDate,
    );

    final cat2 = CategoryModel(
      categoryId: 2,
      categoryGuid: "guid-2",
      categoryName: "Beverages",
      description: "Fresh juice and tea",
      displayOrder: 2,
      isActive: true,
      productCount: 3,
      createdAtUtc: fixedDate,
    );

    final cat3 = CategoryModel(
      categoryId: 3,
      categoryGuid: "guid-3",
      categoryName: "Seasonal Specials",
      description: "Holiday items",
      displayOrder: 3,
      isActive: false,
      productCount: 0,
      createdAtUtc: fixedDate,
    );

    test("CategoryState defaults are correctly initialized", () {
      const state = CategoryState();
      expect(state.isLoading, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.categories, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.filterActive, isNull);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test("filteredCategories filters by search query matching name or description", () {
      final state = CategoryState(
        categories: [cat1, cat2, cat3],
        searchQuery: "juice",
      );

      final filtered = state.filteredCategories;
      expect(filtered.length, 1);
      expect(filtered.first.categoryName, "Beverages");
    });

    test("filteredCategories filters by active status", () {
      final stateActive = CategoryState(
        categories: [cat1, cat2, cat3],
        filterActive: true,
      );
      expect(stateActive.filteredCategories.length, 2);

      final stateInactive = CategoryState(
        categories: [cat1, cat2, cat3],
        filterActive: false,
      );
      expect(stateInactive.filteredCategories.length, 1);
      expect(stateInactive.filteredCategories.first.categoryName, "Seasonal Specials");
    });

    test("copyWith updates state properly", () {
      final state = CategoryState(categories: [cat1]);

      final newState = state.copyWith(
        isLoading: true,
        searchQuery: "coffee",
        successMessage: "Loaded successfully",
      );

      expect(newState.isLoading, isTrue);
      expect(newState.searchQuery, "coffee");
      expect(newState.successMessage, "Loaded successfully");
      expect(newState.categories.length, 1);
    });
  });
}

