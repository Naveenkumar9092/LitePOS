import "dart:async";
import "dart:convert";
import "package:sqflite/sqflite.dart";
import "package:uuid/uuid.dart";
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
    // 1. FAST LOCAL-FIRST: Load categories from SQLite immediately (< 1ms)
    final localList = await _getLocalCategories(isActive);

    // 2. Background sync from server (unblocking UI!)
    unawaited(_syncCategoriesInBackground(isActive));

    if (localList.isNotEmpty && !forceRefresh) {
      return localList;
    }

    return await _fetchRemoteCategories(isActive);
  }

  Future<void> _syncCategoriesInBackground(bool? isActive) async {
    try {
      final remoteList = await _fetchRemoteCategories(isActive);
      if (remoteList.isNotEmpty) {
        await _cacheCategoriesBatch(remoteList);
      }
    } catch (_) {}
  }

  Future<List<CategoryModel>> _fetchRemoteCategories(bool? isActive) async {
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
        unawaited(_cacheCategoriesBatch(categories));
        return categories;
      }
    } catch (_) {}

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
    // 1. FAST LOCAL-FIRST: Save in SQLite immediately (< 1ms)
    final db = await _db.database;
    final maxIdRow = await db.rawQuery("SELECT MAX(CategoryId) as maxId FROM ${DatabaseTables.localCategory}");
    final maxId = (maxIdRow.first["maxId"] as num?)?.toInt() ?? 0;
    final newId = maxId > 0 ? maxId + 1 : (DateTime.now().millisecondsSinceEpoch % 100000);

    final localCategory = CategoryModel(
      categoryId: newId,
      categoryGuid: "offline-$newId",
      categoryName: name.trim(),
      description: description?.trim(),
      categoryImageStorageKey: imageKey,
      displayOrder: displayOrder,
      isActive: true,
      productCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );

    await _cacheCategory(localCategory);

    // Save to LocalSyncOutbox for guaranteed synchronization
    await _recordCategoryInOutbox(localCategory);

    // 2. Next: sync with Online DB in background
    unawaited(_syncCreateCategoryInBackground(localCategory, {
      "categoryName": name,
      "description": description,
      "categoryImageStorageKey": imageKey,
      "displayOrder": displayOrder,
    }));

    return localCategory;
  }

  Future<void> _recordCategoryInOutbox(CategoryModel category) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localSyncOutbox,
        {
          "EventGuid": const Uuid().v4(),
          "IdempotencyKey": "cat-${category.categoryGuid}",
          "EntityType": "CATEGORY",
          "EntityGuid": category.categoryGuid,
          "PayloadJson": jsonEncode(category.toJson()),
          "SyncStatus": 1,
          "RetryCount": 0,
          "CreatedAtUTC": DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> _syncCreateCategoryInBackground(CategoryModel localCat, Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.categories,
        data: body,
      );
      if (response.success && response.data != null) {
        final serverCat = CategoryModel.fromJson(response.data as Map<String, dynamic>);
        final db = await _db.database;
        if (serverCat.categoryId != localCat.categoryId) {
          // Re-map any products referencing the temporary ID to the new server ID
          await db.update(
            DatabaseTables.localProduct,
            {"CategoryId": serverCat.categoryId},
            where: "CategoryId = ?",
            whereArgs: [localCat.categoryId],
          );
          // Delete old temporary ID row
          await db.delete(
            DatabaseTables.localCategory,
            where: "CategoryId = ?",
            whereArgs: [localCat.categoryId],
          );
        }
        await _cacheCategory(serverCat);

        await db.update(
          DatabaseTables.localSyncOutbox,
          {"SyncStatus": 3},
          where: "EntityType = 'CATEGORY' AND EntityGuid = ?",
          whereArgs: [localCat.categoryGuid],
        );
      }
    } catch (_) {}
  }

  Future<CategoryModel> updateCategory(
    int id, {
    required String name,
    String? description,
    String? imageKey,
    required int displayOrder,
    required bool isActive,
  }) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately
    final db = await _db.database;
    await db.update(
      DatabaseTables.localCategory,
      {
        "CategoryName": name,
        "Description": description,
        "CategoryImageStorageKey": imageKey,
        "DisplayOrder": displayOrder,
        "IsActive": isActive ? 1 : 0,
        "UpdatedAtUTC": DateTime.now().toUtc().toIso8601String(),
      },
      where: "CategoryId = ?",
      whereArgs: [id],
    );

    final updatedCat = CategoryModel(
      categoryId: id,
      categoryGuid: "cat-$id",
      categoryName: name,
      description: description,
      categoryImageStorageKey: imageKey,
      displayOrder: displayOrder,
      isActive: isActive,
      productCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.put(
          "${ApiEndpoints.categories}/$id",
          data: {
            "categoryName": name,
            "description": description,
            "categoryImageStorageKey": imageKey,
            "displayOrder": displayOrder,
            "isActive": isActive,
          },
        );
      } catch (_) {}
    }());

    return updatedCat;
  }

  Future<bool> updateCategoryStatus(int id, bool isActive) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately
    final db = await _db.database;
    await db.update(
      DatabaseTables.localCategory,
      {"IsActive": isActive ? 1 : 0},
      where: "CategoryId = ?",
      whereArgs: [id],
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.patch(
          "${ApiEndpoints.categories}/$id/status",
          data: {"isActive": isActive},
        );
      } catch (_) {}
    }());

    return true;
  }

  Future<bool> updateSortOrder(List<Map<String, dynamic>> items) async {
    // 1. FAST LOCAL-FIRST: Update SQLite immediately
    final db = await _db.database;
    for (final item in items) {
      final id = (item["categoryId"] as num?)?.toInt();
      final order = (item["displayOrder"] as num?)?.toInt();
      if (id != null && order != null) {
        await db.update(
          DatabaseTables.localCategory,
          {"DisplayOrder": order},
          where: "CategoryId = ?",
          whereArgs: [id],
        );
      }
    }

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.put(
          ApiEndpoints.categoriesSort,
          data: {"items": items},
        );
      } catch (_) {}
    }());

    return true;
  }

  Future<bool> deleteCategory(int id) async {
    // 1. FAST LOCAL-FIRST: Delete from SQLite immediately
    final db = await _db.database;
    await db.delete(
      DatabaseTables.localCategory,
      where: "CategoryId = ?",
      whereArgs: [id],
    );

    // 2. Next: sync with Online DB in background
    unawaited(() async {
      try {
        await _dioClient.delete("${ApiEndpoints.categories}/$id");
      } catch (_) {}
    }());

    return true;
  }

  Future<void> _cacheCategoriesBatch(List<CategoryModel> categories) async {
    try {
      final db = await _db.database;
      final batch = db.batch();
      for (final c in categories) {
        // Remove duplicate temporary categories with same name
        await db.delete(
          DatabaseTables.localCategory,
          where: "LOWER(CategoryName) = ? AND CategoryId != ?",
          whereArgs: [c.categoryName.trim().toLowerCase(), c.categoryId],
        );
        batch.insert(
          DatabaseTables.localCategory,
          c.toLocalDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> _cacheCategory(CategoryModel c) async {
    try {
      final db = await _db.database;
      await db.insert(
        DatabaseTables.localCategory,
        c.toLocalDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<List<CategoryModel>> _getLocalCategories(bool? isActive) async {
    try {
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
    } catch (_) {
      return [];
    }
  }
}

