import "package:billing_pos_app/features/products/models/product_model.dart";

class CartItemModel {
  final int productId;
  final String productName;
  final double unitPrice;
  final double taxPercentage;
  final int quantity;
  final double discountAmount;
  final String? imageUrl;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.taxPercentage = 0.0,
    this.quantity = 1,
    this.discountAmount = 0.0,
    this.imageUrl,
  });

  factory CartItemModel.fromProduct(ProductModel product, {int quantity = 1}) {
    return CartItemModel(
      productId: product.id,
      productName: product.productName,
      unitPrice: product.sellingPrice,
      taxPercentage: product.taxPercentage,
      quantity: quantity,
      discountAmount: 0.0,
      imageUrl: product.productImageStorageKey,
    );
  }

  double get subTotal => (quantity * unitPrice);
  double get taxableAmount => (subTotal - discountAmount) > 0 ? (subTotal - discountAmount) : 0;
  double get taxAmount => (taxableAmount * (taxPercentage / 100));
  double get lineTotal => taxableAmount + taxAmount;

  CartItemModel copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    double? taxPercentage,
    int? quantity,
    double? discountAmount,
    String? imageUrl,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "productNameSnapshot": productName,
      "unitPrice": unitPrice,
      "quantity": quantity,
      "discountAmount": discountAmount,
      "taxPercentage": taxPercentage,
      "taxAmount": taxAmount,
      "lineTotal": lineTotal,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: (json["productId"] as num).toInt(),
      productName: json["productNameSnapshot"]?.toString() ?? json["productName"]?.toString() ?? "",
      unitPrice: (json["unitPrice"] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json["taxPercentage"] as num?)?.toDouble() ?? 0.0,
      quantity: (json["quantity"] as num?)?.toInt() ?? 1,
      discountAmount: (json["discountAmount"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

