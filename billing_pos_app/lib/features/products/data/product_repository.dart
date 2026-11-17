import "dart:async";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/network/dio_client.dart";
import "../models/product_model.dart";

class PagedProductsResult {
  final List<ProductModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  PagedProductsResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });
}

class ProductRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  ProductRepository(this._dioClient, this._db);

  Future<PagedProductsResult> getProducts({
    int pageNumber = 1,
    int pageSize = 50,
    String? search,
    int? categoryId,
    bool? isAvailable,
    bool? isActive,
  }) async {
    // 1. FAST LOCAL-FIRST: Load seeded/cached items from SQLite immediately (< 2ms)
    final localItems = await getLocalProducts(
      search: search,
      categoryId: categoryId,
      isAvailable: isAvailable,
      isActive: isActive,
    );

    if (localItems.isNotEmpty) {
      // 2. Background sync from server (unblocks POS & UI completely!)
      unawaited(_syncProductsInBackground(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: search,
        categoryId: categoryId,
        isAvailable: isAvailable,
        isActive: isActive,
      ));

      return PagedProductsResult(
        items: localItems,
        totalCount: localItems.length,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    }

    final queryParams = <String, dynamic>{
      "pageNumber": pageNumber,
      "pageSize": pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams["search"] = search;
    if (categoryId != null && categoryId > 0) queryParams["categoryId"] = categoryId;
    if (isAvailable != null) queryParams["isAvailable"] = isAvailable;
    if (isActive != null) queryParams["isActive"] = isActive;

    try {
      final response = await _dioClient.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rawItems = data["items"] as List<dynamic>? ?? [];
        final items = rawItems.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        final totalCount = (data["totalCount"] as num?)?.toInt() ?? items.length;

        // Cache products locally in background without blocking UI
        unawaited(_cacheProductsBatch(items));

        return PagedProductsResult(
          items: items,
          totalCount: totalCount,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
      }
    } catch (_) {}

    return PagedProductsResult(items: localItems, totalCount: localItems.length, pageNumber: pageNumber, pageSize: pageSize);
  }

  Future<void> _syncProductsInBackground({
    int pageNumber = 1,
    int pageSize = 50,
    String? search,
    int? categoryId,
    bool? isAvailable,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      "pageNumber": pageNumber,
      "pageSize": pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams["search"] = search;
    if (categoryId != null && categoryId > 0) queryParams["categoryId"] = categoryId;
    if (isAvailable != null) queryParams["isAvailable"] = isAvailable;
    if (isActive != null) queryParams["isActive"] = isActive;

    try {
      final response = await _dioClient.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rawItems = data["items"] as List<dynamic>? ?? [];
        final items = rawItems.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        if (items.isNotEmpty) {
          await _cacheProductsBatch(items);
        }
      }
    } catch (_) {}
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _dioClient.get(
      "${ApiEndpoints.products}/$id",
    );

    if (response.success && response.data != null) {
      final product = ProductModel.fromJson(response.data as Map<String, dynamic>);
      await _cacheProduct(product);
      return product;
    }
    throw Exception(response.message);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    // 1. FAST LOCAL-FIRST: Save in SQLite immediately (< 2ms)
    final db = await _db.database;
    final maxIdRow = await db.rawQuery("SELECT MAX(ProductId) as maxId FROM ${DatabaseTables.localProduct}");
    final maxId = (maxIdRow.first["maxId"] as num?)?.toInt() ?? 0;
    final newId = maxId > 0 ? maxId + 1 : (DateTime.now().millisecondsSinceEpoch % 100000);

    final localProduct = ProductModel(
      id: newId,
      productGuid: "offline-$newId",
      companyId: (data["companyId"] as num?)?.toInt() ?? 1,
      categoryId: (data["categoryId"] as num?)?.toInt() ?? 1,
      categoryName: data["categoryName"]?.toString() ?? "General",
      productName: data["productName"]?.toString() ?? "New Product",
      description: data["description"]?.toString(),
      productImageStorageKey: data["productImageStorageKey"]?.toString(),
      sellingPrice: (data["sellingPrice"] as num?)?.toDouble() ?? 0.0,
      taxId: (data["taxId"] as num?)?.toInt(),
      taxPercentage: (data["taxPercentage"] as num?)?.toDouble() ?? 0.0,
      hsnCode: data["hsnCode"]?.toString(),
      isAvailable: data["isAvailable"] as bool? ?? true,
      isActive: data["isActive"] as bool? ?? true,
      createdAtUtc: DateTime.now().toUtc(),
    );

    await _cacheProduct(localProduct);

    // 2. Next: sync with Online DB in background
    unawaited(_syncCreateProductInBackground(localProduct, data));

    return localProduct;
  }

  Future<void> _syncCreateProductInBackground(ProductModel localProduct, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.products,
        data: data,
      );
      if (response.success && response.data != null) {
        final serverProduct = ProductModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheProduct(serverProduct);
      }
    } catch (_) {}
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately
    final db = await _db.database;
    final updateMap = <String, dynamic>{
      if (data["productName"] != null) "ProductName": data["productName"],
      if (data["description"] != null) "Description": data["description"],
      if (data["productImageStorageKey"] != null) "ProductImageStorageKey": data["productImageStorageKey"],
      if (data["sellingPrice"] != null) "SellingPrice": (data["sellingPrice"] as num).toDouble(),
      if (data["taxPercentage"] != null) "TaxPercentage": (data["taxPercentage"] as num).toDouble(),
      if (data["taxId"] != null) "TaxId": (data["taxId"] as num).toInt(),
      if (data["hsnCode"] != null) "HSNCode": data["hsnCode"],
      if (data["categoryId"] != null) "CategoryId": (data["categoryId"] as num).toInt(),
      if (data["isAvailable"] != null) "IsAvailable": (data["isAvailable"] as bool) ? 1 : 0,
      if (data["isActive"] != null) "IsActive": (data["isActive"] as bool) ? 1 : 0,
      "UpdatedAtUTC": DateTime.now().toUtc().toIso8601String(),
    };

    await db.update(
      DatabaseTables.localProduct,
      updateMap,
      where: "ProductId = ?",
      whereArgs: [id],
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.put("${ApiEndpoints.products}/$id", data: data);
      } catch (_) {}
    }());

    // Return updated local product
    final rows = await db.query(DatabaseTables.localProduct, where: "ProductId = ?", whereArgs: [id]);
    if (rows.isNotEmpty) {
      return ProductModel.fromSqlite(rows.first);
    }

    return ProductModel.fromJson(data);
  }

  Future<bool> toggleAvailability(int id, bool isAvailable) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately (0ms UI lag)
    await _updateLocalAvailability(id, isAvailable);

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.patch(
          "${ApiEndpoints.products}/$id/availability",
          data: {"isAvailable": isAvailable},
        );
      } catch (_) {}
    }());

    return true;
  }

  Future<bool> toggleStatus(int id, bool isActive) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately (0ms UI lag)
    await _updateLocalStatus(id, isActive);

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.patch(
          "${ApiEndpoints.products}/$id/status",
          data: {"isActive": isActive},
        );
      } catch (_) {}
    }());

    return true;
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.productSearch,
        queryParameters: {"query": query},
      );

      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      return await getLocalProducts(search: query, isAvailable: true, isActive: true);
    }
    return [];
  }

  Future<List<CategoryModel>> getCategories() async {
    // 1. FAST LOCAL-FIRST: Load from local SQLite immediately
    final local = await getLocalCategories();
    if (local.isNotEmpty) {
      unawaited(_syncCategoriesInBackground());
      return local;
    }

    try {
      final response = await _dioClient.get(
        ApiEndpoints.productCategoriesDropdown,
      );

      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final items = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
        unawaited(_cacheCategoriesBatch(items));
        return items;
      }
    } catch (_) {}
    return local;
  }

  Future<void> _syncCategoriesInBackground() async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.productCategoriesDropdown,
      );
      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final items = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
        await _cacheCategoriesBatch(items);
      }
    } catch (_) {}
  }

  // --- SQLite Local Persistence ---

  Future<List<ProductModel>> getLocalProducts({
    String? search,
    int? categoryId,
    bool? isAvailable,
    bool? isActive,
  }) async {
    try {
      final db = await _db.database;
      String whereClause = "1=1";
      final List<dynamic> whereArgs = [];

      if (search != null && search.isNotEmpty) {
        whereClause += " AND (ProductName LIKE ? OR HSNCode LIKE ?)";
        whereArgs.add("%$search%");
        whereArgs.add("%$search%");
      }
      if (categoryId != null && categoryId > 0) {
        whereClause += " AND CategoryId = ?";
        whereArgs.add(categoryId);
      }
      if (isAvailable != null) {
        whereClause += " AND IsAvailable = ?";
        whereArgs.add(isAvailable ? 1 : 0);
      }
      if (isActive != null) {
        whereClause += " AND IsActive = ?";
        whereArgs.add(isActive ? 1 : 0);
      }

      final rows = await db.query(
        DatabaseTables.localProduct,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: "ProductName ASC",
      );

      return rows.map((r) => ProductModel.fromSqlite(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryModel>> getLocalCategories() async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        DatabaseTables.localCategory,
        where: "IsActive = 1",
        orderBy: "DisplayOrder ASC",
      );
      return rows.map((r) => CategoryModel.fromSqlite(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheProductsBatch(List<ProductModel> products) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      for (final p in products) {
        batch.insert(
          DatabaseTables.localProduct,
          p.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> _cacheCategoriesBatch(List<CategoryModel> categories) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      for (final cat in categories) {
        batch.insert(
          DatabaseTables.localCategory,
          cat.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> _cacheProduct(ProductModel product) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localProduct,
        product.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> _updateLocalAvailability(int id, bool isAvailable) async {
    try {
      final db = await _db.database;
      await db.update(
        DatabaseTables.localProduct,
        {"IsAvailable": isAvailable ? 1 : 0},
        where: "ProductId = ?",
        whereArgs: [id],
      );
    } catch (_) {}
  }

  Future<void> _updateLocalStatus(int id, bool isActive) async {
    try {
      final db = await _db.database;
      await db.update(
        DatabaseTables.localProduct,
        {"IsActive": isActive ? 1 : 0},
        where: "ProductId = ?",
        whereArgs: [id],
      );
    } catch (_) {}
  }
}

