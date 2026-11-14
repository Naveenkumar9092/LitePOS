class CategoryModel {
  final int categoryId;
  final String categoryGuid;
  final String categoryName;
  final String? description;
  final String? categoryImageStorageKey;
  final int displayOrder;
  final bool isActive;
  final int productCount;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  int get id => categoryId;

  CategoryModel({
    required this.categoryId,
    required this.categoryGuid,
    required this.categoryName,
    this.description,
    this.categoryImageStorageKey,
    required this.displayOrder,
    required this.isActive,
    this.productCount = 0,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: (json["categoryId"] ?? json["id"] as num).toInt(),
      categoryGuid: json["categoryGuid"]?.toString() ?? "",
      categoryName: json["categoryName"]?.toString() ?? "",
      description: json["description"]?.toString(),
      categoryImageStorageKey: json["categoryImageStorageKey"]?.toString(),
      displayOrder: (json["displayOrder"] as num?)?.toInt() ?? 0,
      isActive: json["isActive"] as bool? ?? true,
      productCount: (json["productCount"] as num?)?.toInt() ?? 0,
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
      "categoryId": categoryId,
      "categoryGuid": categoryGuid,
      "categoryName": categoryName,
      "description": description,
      "categoryImageStorageKey": categoryImageStorageKey,
      "displayOrder": displayOrder,
      "isActive": isActive,
      "productCount": productCount,
      "createdAtUtc": createdAtUtc.toIso8601String(),
      "updatedAtUtc": updatedAtUtc?.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalDbMap() {
    return {
      "CategoryId": categoryId,
      "CategoryGuid": categoryGuid,
      "CategoryName": categoryName,
      "Description": description,
      "CategoryImageStorageKey": categoryImageStorageKey,
      "DisplayOrder": displayOrder,
      "IsActive": isActive ? 1 : 0,
      "CreatedAtUTC": createdAtUtc.toIso8601String(),
      "UpdatedAtUTC": updatedAtUtc?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqlite() => toLocalDbMap();

  factory CategoryModel.fromLocalDbMap(Map<String, dynamic> map, {int productCount = 0}) {
    return CategoryModel(
      categoryId: (map["CategoryId"] as num).toInt(),
      categoryGuid: map["CategoryGuid"]?.toString() ?? "",
      categoryName: map["CategoryName"]?.toString() ?? "",
      description: map["Description"]?.toString(),
      categoryImageStorageKey: map["CategoryImageStorageKey"]?.toString(),
      displayOrder: (map["DisplayOrder"] as num?)?.toInt() ?? 0,
      isActive: (map["IsActive"] as num?)?.toInt() == 1,
      productCount: productCount,
      createdAtUtc: map["CreatedAtUTC"] != null
          ? DateTime.tryParse(map["CreatedAtUTC"].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: map["UpdatedAtUTC"] != null
          ? DateTime.tryParse(map["UpdatedAtUTC"].toString())
          : null,
    );
  }

  factory CategoryModel.fromSqlite(Map<String, dynamic> map, {int productCount = 0}) =>
      CategoryModel.fromLocalDbMap(map, productCount: productCount);

  CategoryModel copyWith({
    int? categoryId,
    String? categoryGuid,
    String? categoryName,
    String? description,
    String? categoryImageStorageKey,
    int? displayOrder,
    bool? isActive,
    int? productCount,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryGuid: categoryGuid ?? this.categoryGuid,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      categoryImageStorageKey: categoryImageStorageKey ?? this.categoryImageStorageKey,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}
