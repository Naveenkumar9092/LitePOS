import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/billing/models/cart_item_model.dart";
import "package:billing_pos_app/features/billing/presentation/cart_state.dart";

void main() {
  group("CartItemModel & CartState Calculations Tests", () {
    test("CartItemModel computes subTotal, taxable, tax and lineTotal correctly", () {
      // 2 Cappuccinos @ 120 each = 240 subtotal, 5% tax = 12.00, line total = 252.00
      final item = CartItemModel(
        productId: 1,
        productName: "Cappuccino",
        unitPrice: 120.0,
        taxPercentage: 5.0,
        quantity: 2,
        discountAmount: 0.0,
      );

      expect(item.subTotal, 240.0);
      expect(item.taxableAmount, 240.0);
      expect(item.taxAmount, 12.0);
      expect(item.lineTotal, 252.0);
    });

    test("CartItemModel applies line discount before tax", () {
      // 1 item @ 200, 20 discount -> 180 taxable, 5% tax -> 9 tax, line total 189
      final item = CartItemModel(
        productId: 2,
        productName: "Dessert Plate",
        unitPrice: 200.0,
        taxPercentage: 5.0,
        quantity: 1,
        discountAmount: 20.0,
      );

      expect(item.subTotal, 200.0);
      expect(item.taxableAmount, 180.0);
      expect(item.taxAmount, 9.0);
      expect(item.lineTotal, 189.0);
    });

    test("CartState aggregates multiple items, tax and grand total correctly", () {
      final item1 = CartItemModel(
        productId: 1,
        productName: "Espresso",
        unitPrice: 100.0,
        taxPercentage: 5.0,
        quantity: 2, // 200 subtotal, 10 tax
      );

      final item2 = CartItemModel(
        productId: 2,
        productName: "Sandwich",
        unitPrice: 150.0,
        taxPercentage: 5.0,
        quantity: 1, // 150 subtotal, 7.5 tax
      );

      final state = CartState(items: [item1, item2]);

      expect(state.totalItemsCount, 3);
      expect(state.subTotal, 350.0);
      expect(state.totalTax, 17.5);
      expect(state.grandTotal, 367.5);
    });

    test("CartState applies overall discount properly", () {
      final item1 = CartItemModel(
        productId: 1,
        productName: "Espresso",
        unitPrice: 100.0,
        taxPercentage: 5.0,
        quantity: 2, // 200 subtotal, 10 tax
      );

      final state = CartState(items: [item1], discountAmount: 50.0);

      expect(state.subTotal, 200.0);
      expect(state.effectiveDiscount, 50.0);
      expect(state.taxableAmount, 150.0);
      expect(state.grandTotal, 160.0); // 150 + 10 tax
    });
  });
}

