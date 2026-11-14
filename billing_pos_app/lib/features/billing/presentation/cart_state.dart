import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";
import "../models/billing_invoice_model.dart";
import "../models/cart_item_model.dart";

class CartState {
  final List<CartItemModel> items;
  final int? customerId;
  final String? customerName;
  final double discountAmount;
  final String? note;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.discountAmount = 0.0,
    this.note,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemsCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subTotal => items.fold(0.0, (sum, i) => sum + i.subTotal);

  double get totalLineDiscounts => items.fold(0.0, (sum, i) => sum + i.discountAmount);

  double get effectiveDiscount => discountAmount > 0 ? discountAmount : totalLineDiscounts;

  double get taxableAmount {
    final net = subTotal - effectiveDiscount;
    return net > 0 ? net : 0.0;
  }

  double get totalTax => items.fold(0.0, (sum, i) => sum + i.taxAmount);

  double get grandTotal => taxableAmount + totalTax;

  CartState copyWith({
    List<CartItemModel>? items,
    int? customerId,
    String? customerName,
    double? discountAmount,
    String? note,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      discountAmount: discountAmount ?? this.discountAmount,
      note: note ?? this.note,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addToCart(ProductModel product, {int quantity = 1}) {
    if (!product.isAvailable) return;

    final existingIndex = state.items.indexWhere((i) => i.productId == product.id);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      final newItems = [...state.items];
      newItems[existingIndex] = updated;
      state = state.copyWith(items: newItems);
    } else {
      final newItem = CartItemModel.fromProduct(product, quantity: quantity);
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeFromCart(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final newItems = state.items.map((i) {
      if (i.productId == productId) {
        return i.copyWith(quantity: quantity);
      }
      return i;
    }).toList();

    state = state.copyWith(items: newItems);
  }

  void incrementQuantity(int productId) {
    final item = state.items.firstWhere((i) => i.productId == productId);
    updateQuantity(productId, item.quantity + 1);
  }

  void decrementQuantity(int productId) {
    final item = state.items.firstWhere((i) => i.productId == productId);
    updateQuantity(productId, item.quantity - 1);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount < 0 ? 0.0 : discount);
  }

  void setCustomer(int? id, String? name) {
    if (id == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(customerId: id, customerName: name);
    }
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void clearCart() {
    state = const CartState();
  }

  void loadFromInvoice(BillingInvoiceModel invoice) {
    final cartItems = invoice.items.map((it) => CartItemModel(
      productId: it.productId,
      productName: it.productNameSnapshot,
      unitPrice: it.unitPrice,
      quantity: it.quantity,
      discountAmount: it.discountAmount,
      taxPercentage: it.taxPercentage,
    )).toList();

    state = CartState(
      items: cartItems,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      discountAmount: invoice.discountAmount,
    );
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

