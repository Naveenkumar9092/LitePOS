import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";
import "package:billing_pos_app/features/products/presentation/widgets/product_card.dart";

void main() {
  group("Product Widgets Tests", () {
    testWidgets("ProductCard renders product details and single selling price", (tester) async {
      final product = ProductModel(
        id: 1,
        productGuid: "guid-001",
        companyId: 1,
        categoryId: 1,
        categoryName: "Coffee",
        productName: "Cappuccino",
        description: "Espresso with milk foam",
        sellingPrice: 120.0,
        taxPercentage: 5.0,
        hsnCode: "0901",
        isAvailable: true,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              isAdmin: true,
            ),
          ),
        ),
      );

      expect(find.text("CAPPUCCINO"), findsNothing); // Matches case
      expect(find.text("Cappuccino"), findsOneWidget);
      expect(find.text("COFFEE"), findsOneWidget);
      expect(find.text("AVAILABLE"), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets("ProductCard shows OUT OF STOCK when isAvailable is false", (tester) async {
      final product = ProductModel(
        id: 2,
        productGuid: "guid-002",
        companyId: 1,
        categoryId: 2,
        categoryName: "Snacks",
        productName: "Sandwich",
        sellingPrice: 100.0,
        taxPercentage: 5.0,
        hsnCode: "1905",
        isAvailable: false,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              isAdmin: false,
            ),
          ),
        ),
      );

      expect(find.text("Sandwich"), findsOneWidget);
      expect(find.text("OUT OF STOCK"), findsOneWidget);
    });

    testWidgets("ProductCard switch triggers onAvailabilityChanged", (tester) async {
      bool toggled = false;
      bool targetVal = false;

      final product = ProductModel(
        id: 1,
        productGuid: "guid-001",
        companyId: 1,
        categoryId: 1,
        categoryName: "Coffee",
        productName: "Cappuccino",
        sellingPrice: 120.0,
        taxPercentage: 5.0,
        hsnCode: "0901",
        isAvailable: true,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              isAdmin: true,
              onAvailabilityChanged: (val) {
                toggled = true;
                targetVal = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggled, true);
      expect(targetVal, false);
    });
  });
}

