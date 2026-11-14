import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/billing/presentation/cart_state.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";

void main() {
  group("CartNotifier Tests", () {
    final product1 = ProductModel(
      id: 1,
      productGuid: "guid-001",
      companyId: 1,
      categoryId: 1,
      categoryName: "Coffee",
      productName: "Espresso",
      sellingPrice: 100.0,
      taxPercentage: 5.0,
      isAvailable: true,
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    final productUnavailable = ProductModel(
      id: 2,
      productGuid: "guid-002",
      companyId: 1,
      categoryId: 1,
      categoryName: "Coffee",
      productName: "Seasonal Latte",
      sellingPrice: 150.0,
      taxPercentage: 5.0,
      isAvailable: false, // Out of stock
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    test("addToCart adds new item to cart", () {
      final notifier = CartNotifier();
      notifier.addToCart(product1);

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.productId, 1);
      expect(notifier.state.items.first.quantity, 1);
      expect(notifier.state.grandTotal, 105.0);
    });

    test("addToCart increments quantity when adding duplicate item", () {
      final notifier = CartNotifier();
      notifier.addToCart(product1);
      notifier.addToCart(product1, quantity: 2);

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 3);
      expect(notifier.state.subTotal, 300.0);
      expect(notifier.state.grandTotal, 315.0);
    });

    test("addToCart does not add unavailable product", () {
      final notifier = CartNotifier();
      notifier.addToCart(productUnavailable);

      expect(notifier.state.items, isEmpty);
    });

    test("increment and decrement update quantity properly", () {
      final notifier = CartNotifier();
      notifier.addToCart(product1, quantity: 2);

      notifier.incrementQuantity(1);
      expect(notifier.state.items.first.quantity, 3);

      notifier.decrementQuantity(1);
      expect(notifier.state.items.first.quantity, 2);

      notifier.decrementQuantity(1);
      notifier.decrementQuantity(1); // drops to 0 -> should remove item
      expect(notifier.state.items, isEmpty);
    });

    test("clearCart resets entire cart state", () {
      final notifier = CartNotifier();
      notifier.addToCart(product1);
      notifier.setDiscount(20.0);
      notifier.setCustomer(5, "VIP Customer");

      expect(notifier.state.items.isNotEmpty, isTrue);

      notifier.clearCart();

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.discountAmount, 0.0);
      expect(notifier.state.customerId, isNull);
    });
  });
}

