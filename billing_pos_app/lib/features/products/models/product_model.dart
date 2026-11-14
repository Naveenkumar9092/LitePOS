export "package:billing_pos_app/features/categories/models/category_model.dart";

class ProductModel {
  final int id;
  final String productGuid;
  final int companyId;
  final int categoryId;
  final String categoryName;
  final String productName;
  final String? description;
  final String? productImageStorageKey;
  final double sellingPrice;
  final int? taxId;
  final double taxPercentage;
  final String? hsnCode;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  ProductModel({
    required this.id,
    required this.productGuid,
    required this.companyId,
    required this.categoryId,
    required this.categoryName,
    required this.productName,
    this.description,
    this.productImageStorageKey,
    required this.sellingPrice,
    this.taxId,
    required this.taxPercentage,
    this.hsnCode,
    required this.isAvailable,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json["productId"] ?? json["id"] as num).toInt(),
      productGuid: json["productGuid"]?.toString() ?? "",
      companyId: (json["companyId"] as num?)?.toInt() ?? 1,
      categoryId: (json["categoryId"] as num?)?.toInt() ?? 1,
      categoryName: json["categoryName"]?.toString() ?? "",
      productName: json["productName"]?.toString() ?? "",
      description: json["description"]?.toString(),
      productImageStorageKey: json["productImageStorageKey"]?.toString(),
      sellingPrice: (json["sellingPrice"] as num?)?.toDouble() ?? 0.0,
      taxId: (json["taxId"] as num?)?.toInt(),
      taxPercentage: (json["taxPercentage"] as num?)?.toDouble() ?? 0.0,
      hsnCode: json["hsnCode"]?.toString(),
      isAvailable: json["isAvailable"] as bool? ?? true,
      isActive: json["isActive"] as bool? ?? true,
      createdAtUtc: json["createdAtUtc"] != null
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: json["updatedAtUtc"] != null
          ? DateTime.tryParse(json["updatedAtUtc"].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productId": id,
      "productGuid": productGuid,
      "companyId": companyId,
      "categoryId": categoryId,
      "categoryName": categoryName,
      "productName": productName,
      "description": description,
      "productImageStorageKey": productImageStorageKey,
      "sellingPrice": sellingPrice,
      "taxId": taxId,
      "taxPercentage": taxPercentage,
      "hsnCode": hsnCode,
      "isAvailable": isAvailable,
      "isActive": isActive,
      "createdAtUtc": createdAtUtc.toIso8601String(),
      "updatedAtUtc": updatedAtUtc?.toIso8601String(),
    };
  }

  factory ProductModel.fromSqlite(Map<String, dynamic> map, {String categoryName = ""}) {
    return ProductModel(
      id: (map["ProductId"] as num).toInt(),
      productGuid: map["ProductGuid"]?.toString() ?? "",
      companyId: (map["CompanyId"] as num?)?.toInt() ?? 1,
      categoryId: (map["CategoryId"] as num?)?.toInt() ?? 1,
      categoryName: categoryName.isNotEmpty ? categoryName : "Category ${map["CategoryId"]}",
      productName: map["ProductName"]?.toString() ?? "",
      description: map["Description"]?.toString(),
      productImageStorageKey: map["ProductImageStorageKey"]?.toString(),
      sellingPrice: (map["SellingPrice"] as num?)?.toDouble() ?? 0.0,
      taxId: (map["TaxId"] as num?)?.toInt(),
      taxPercentage: (map["TaxPercentage"] as num?)?.toDouble() ?? 0.0,
      hsnCode: map["HSNCode"]?.toString(),
      isAvailable: (map["IsAvailable"] as num?) == 1,
      isActive: (map["IsActive"] as num?) == 1,
      createdAtUtc: map["CreatedAtUTC"] != null
          ? DateTime.tryParse(map["CreatedAtUTC"].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: map["UpdatedAtUTC"] != null
          ? DateTime.tryParse(map["UpdatedAtUTC"].toString())
          : null,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      "ProductId": id,
      "ProductGuid": productGuid,
      "CompanyId": companyId,
      "CategoryId": categoryId,
      "ProductName": productName,
      "Description": description,
      "ProductImageStorageKey": productImageStorageKey,
      "SellingPrice": sellingPrice,
      "TaxId": taxId,
      "TaxPercentage": taxPercentage,
      "HSNCode": hsnCode,
      "IsAvailable": isAvailable ? 1 : 0,
      "IsActive": isActive ? 1 : 0,
      "CreatedAtUTC": createdAtUtc.toIso8601String(),
      "UpdatedAtUTC": updatedAtUtc?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    String? productGuid,
    int? companyId,
    int? categoryId,
    String? categoryName,
    String? productName,
    String? description,
    String? productImageStorageKey,
    double? sellingPrice,
    int? taxId,
    double? taxPercentage,
    String? hsnCode,
    bool? isAvailable,
    bool? isActive,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productGuid: productGuid ?? this.productGuid,
      companyId: companyId ?? this.companyId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      productImageStorageKey: productImageStorageKey ?? this.productImageStorageKey,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxId: taxId ?? this.taxId,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      hsnCode: hsnCode ?? this.hsnCode,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}

