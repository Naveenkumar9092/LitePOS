import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";
import "package:billing_pos_app/features/categories/presentation/widgets/category_card.dart";
import "package:billing_pos_app/features/categories/presentation/widgets/category_form_dialog.dart";

void main() {
  group("Category Widgets Tests", () {
    final fixedDate = DateTime.utc(2026, 11, 13, 10, 0, 0);

    testWidgets("CategoryCard renders details, product count badge and order badge", (tester) async {
      final category = CategoryModel(
        categoryId: 1,
        categoryGuid: "guid-001",
        categoryName: "Specialty Coffee",
        description: "Fresh artisanal brews",
        displayOrder: 1,
        isActive: true,
        productCount: 7,
        createdAtUtc: fixedDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: category,
              isAdmin: true,
            ),
          ),
        ),
      );

      expect(find.text("#1"), findsOneWidget);
      expect(find.text("Specialty Coffee"), findsOneWidget);
      expect(find.text("Fresh artisanal brews"), findsOneWidget);
      expect(find.text("7 Products"), findsOneWidget);
      expect(find.text("Active"), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets("CategoryFormDialog renders in Create mode with empty fields", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryFormDialog(),
          ),
        ),
      );

      expect(find.text("Add New Category"), findsOneWidget);
      expect(find.text("Category Name *"), findsOneWidget);
      expect(find.text("Description"), findsOneWidget);
      expect(find.text("Display Order"), findsOneWidget);
      expect(find.text("Create Category"), findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);
    });

    testWidgets("CategoryFormDialog renders in Edit mode with existing data and active switch", (tester) async {
      final category = CategoryModel(
        categoryId: 2,
        categoryGuid: "guid-002",
        categoryName: "Hot Coffee",
        description: "Fresh hot brews",
        displayOrder: 2,
        isActive: true,
        productCount: 10,
        createdAtUtc: fixedDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryFormDialog(category: category),
          ),
        ),
      );

      expect(find.text("Edit Category"), findsOneWidget);
      expect(find.text("Hot Coffee"), findsOneWidget);
      expect(find.text("Fresh hot brews"), findsOneWidget);
      expect(find.text("2"), findsOneWidget);
      expect(find.text("Active Status"), findsOneWidget);
      expect(find.text("Update Category"), findsOneWidget);
    });
  });
}
