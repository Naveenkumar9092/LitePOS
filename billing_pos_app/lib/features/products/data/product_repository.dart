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
    } catch (_) {
      // Offline fallback: load from SQLite
      final localItems = await getLocalProducts(
        search: search,
        categoryId: categoryId,
        isAvailable: isAvailable,
        isActive: isActive,
      );
      return PagedProductsResult(
        items: localItems,
        totalCount: localItems.length,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    }

    return PagedProductsResult(items: [], totalCount: 0, pageNumber: 1, pageSize: pageSize);
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
    final response = await _dioClient.post(
      ApiEndpoints.products,
      data: data,
    );

    if (response.success && response.data != null) {
      final product = ProductModel.fromJson(response.data as Map<String, dynamic>);
      await _cacheProduct(product);
      return product;
    } else {
      throw Exception(response.message);
    }
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      "${ApiEndpoints.products}/$id",
      data: data,
    );

    if (response.success && response.data != null) {
      final product = ProductModel.fromJson(response.data as Map<String, dynamic>);
      await _cacheProduct(product);
      return product;
    } else {
      throw Exception(response.message);
    }
  }

  Future<bool> toggleAvailability(int id, bool isAvailable) async {
    final response = await _dioClient.patch(
      "${ApiEndpoints.products}/$id/availability",
      data: {"isAvailable": isAvailable},
    );
    if (response.success) {
      await _updateLocalAvailability(id, isAvailable);
      return true;
    }
    return false;
  }

  Future<bool> toggleStatus(int id, bool isActive) async {
    final response = await _dioClient.patch(
      "${ApiEndpoints.products}/$id/status",
      data: {"isActive": isActive},
    );
    if (response.success) {
      await _updateLocalStatus(id, isActive);
      return true;
    }
    return false;
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
    } catch (_) {
      return await getLocalCategories();
    }
    return await getLocalCategories();
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

