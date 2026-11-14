import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/categories/models/category_model.dart";

void main() {
  group("CategoryModel Tests", () {
    final fixedDate = DateTime.utc(2026, 11, 13, 10, 0, 0);

    test("CategoryModel serializes to and from JSON correctly", () {
      final json = {
        "categoryId": 5,
        "categoryGuid": "cat-guid-123",
        "categoryName": "Desserts",
        "description": "Sweet treats and pastries",
        "categoryImageStorageKey": "desserts.png",
        "displayOrder": 5,
        "isActive": true,
        "productCount": 8,
        "createdAtUtc": fixedDate.toIso8601String(),
        "updatedAtUtc": fixedDate.toIso8601String(),
      };

      final model = CategoryModel.fromJson(json);

      expect(model.categoryId, 5);
      expect(model.id, 5);
      expect(model.categoryGuid, "cat-guid-123");
      expect(model.categoryName, "Desserts");
      expect(model.description, "Sweet treats and pastries");
      expect(model.categoryImageStorageKey, "desserts.png");
      expect(model.displayOrder, 5);
      expect(model.isActive, isTrue);
      expect(model.productCount, 8);
      expect(model.createdAtUtc, fixedDate);

      final outputJson = model.toJson();
      expect(outputJson["categoryId"], 5);
      expect(outputJson["categoryName"], "Desserts");
      expect(outputJson["productCount"], 8);
    });

    test("CategoryModel serializes to and from local SQLite map correctly", () {
      final dbMap = {
        "CategoryId": 2,
        "CategoryGuid": "beverage-guid-456",
        "CategoryName": "Beverages",
        "Description": "Cold and hot drinks",
        "CategoryImageStorageKey": null,
        "DisplayOrder": 2,
        "IsActive": 1,
        "CreatedAtUTC": fixedDate.toIso8601String(),
        "UpdatedAtUTC": null,
      };

      final model = CategoryModel.fromLocalDbMap(dbMap, productCount: 4);

      expect(model.categoryId, 2);
      expect(model.categoryName, "Beverages");
      expect(model.isActive, isTrue);
      expect(model.productCount, 4);

      final toDb = model.toLocalDbMap();
      expect(toDb["CategoryId"], 2);
      expect(toDb["CategoryName"], "Beverages");
      expect(toDb["IsActive"], 1);
    });

    test("copyWith updates fields properly", () {
      final original = CategoryModel(
        categoryId: 1,
        categoryGuid: "guid-001",
        categoryName: "Coffee",
        displayOrder: 1,
        isActive: true,
        productCount: 3,
        createdAtUtc: fixedDate,
      );

      final updated = original.copyWith(
        categoryName: "Specialty Coffee",
        displayOrder: 10,
        isActive: false,
      );

      expect(updated.categoryId, 1);
      expect(updated.categoryName, "Specialty Coffee");
      expect(updated.displayOrder, 10);
      expect(updated.isActive, isFalse);
      expect(updated.productCount, 3);
    });
  });
}

