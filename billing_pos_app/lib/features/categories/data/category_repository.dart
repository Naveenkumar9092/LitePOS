import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/network/dio_client.dart";
import "../models/category_model.dart";

class CategoryRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  CategoryRepository(this._dioClient, this._db);

  Future<List<CategoryModel>> getCategories({bool? isActive, bool forceRefresh = false}) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams["isActive"] = isActive;

    try {
      final response = await _dioClient.get(
        ApiEndpoints.categories,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final list = response.data as List<dynamic>;
        final categories = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();

        // Cache categories locally
        for (final c in categories) {
          await _cacheCategory(c);
        }

        return categories;
      }
    } catch (_) {
      // Offline fallback
    }

    // Load from local SQLite
    return await _getLocalCategories(isActive);
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.categories}/$id");
      if (response.success && response.data != null) {
        final cat = CategoryModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheCategory(cat);
        return cat;
      }
    } catch (_) {
      // Fallback to local
    }

    final db = await _db.database;
    final results = await db.query(
      DatabaseTables.localCategory,
      where: "CategoryId = ?",
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return CategoryModel.fromLocalDbMap(results.first);
    }
    return null;
  }

  Future<CategoryModel> createCategory({
    required String name,
    String? description,
    String? imageKey,
    int displayOrder = 0,
  }) async {
    final body = {
      "categoryName": name,
      "description": description,
      "categoryImageStorageKey": imageKey,
      "displayOrder": displayOrder,
    };

    final response = await _dioClient.post(
      ApiEndpoints.categories,
      data: body,
    );

    if (response.success && response.data != null) {
      final cat = CategoryModel.fromJson(response.data as Map<String, dynamic>);
      await _cacheCategory(cat);
      return cat;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : "Failed to create category");
    }
  }

  Future<CategoryModel> updateCategory(
    int id, {
    required String name,
    String? description,
    String? imageKey,
    required int displayOrder,
    required bool isActive,
  }) async {
    final body = {
      "categoryName": name,
      "description": description,
      "categoryImageStorageKey": imageKey,
      "displayOrder": displayOrder,
      "isActive": isActive,
    };

    final response = await _dioClient.put(
      "${ApiEndpoints.categories}/$id",
      data: body,
    );

    if (response.success && response.data != null) {
      final cat = CategoryModel.fromJson(response.data as Map<String, dynamic>);
      await _cacheCategory(cat);
      return cat;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : "Failed to update category");
    }
  }

  Future<bool> updateCategoryStatus(int id, bool isActive) async {
    final response = await _dioClient.patch(
      "${ApiEndpoints.categories}/$id/status",
      data: {"isActive": isActive},
    );

    if (response.success) {
      final db = await _db.database;
      await db.update(
        DatabaseTables.localCategory,
        {"IsActive": isActive ? 1 : 0},
        where: "CategoryId = ?",
        whereArgs: [id],
      );
      return true;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : "Failed to update status");
    }
  }

  Future<bool> updateSortOrder(List<Map<String, dynamic>> items) async {
    final response = await _dioClient.put(
      ApiEndpoints.categoriesSort,
      data: {"items": items},
    );

    if (response.success) {
      final db = await _db.database;
      for (final item in items) {
        await db.update(
          DatabaseTables.localCategory,
          {"DisplayOrder": item["displayOrder"]},
          where: "CategoryId = ?",
          whereArgs: [item["categoryId"]],
        );
      }
      return true;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : "Failed to update sort order");
    }
  }

  Future<bool> deleteCategory(int id) async {
    final response = await _dioClient.delete("${ApiEndpoints.categories}/$id");

    if (response.success) {
      final db = await _db.database;
      await db.delete(
        DatabaseTables.localCategory,
        where: "CategoryId = ?",
        whereArgs: [id],
      );
      return true;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : "Failed to delete category");
    }
  }

  Future<void> _cacheCategory(CategoryModel c) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.localCategory,
      c.toLocalDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryModel>> _getLocalCategories(bool? isActive) async {
    final db = await _db.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (isActive != null) {
      whereClause = "IsActive = ?";
      whereArgs = [isActive ? 1 : 0];
    }

    final results = await db.query(
      DatabaseTables.localCategory,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: "DisplayOrder ASC, CategoryName ASC",
    );

    // Also get product counts from local product table if possible
    final productCounts = <int, int>{};
    try {
      final productResults = await db.rawQuery(
        "SELECT CategoryId, COUNT(*) as cnt FROM ${DatabaseTables.localProduct} WHERE IsActive = 1 GROUP BY CategoryId",
      );
      for (final row in productResults) {
        final catId = (row["CategoryId"] as num).toInt();
        final cnt = (row["cnt"] as num).toInt();
        productCounts[catId] = cnt;
      }
    } catch (_) {}

    return results
        .map((e) => CategoryModel.fromLocalDbMap(
              e,
              productCount: productCounts[(e["CategoryId"] as num).toInt()] ?? 0,
            ))
        .toList();
  }
}

