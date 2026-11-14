import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/products/models/product_model.dart";

void main() {
  group("Product & Category Model Tests", () {
    test("ProductModel deserializes and serializes JSON with single selling price", () {
      final json = {
        "productId": 10,
        "productGuid": "550e8400-e29b-41d4-a716-446655440000",
        "companyId": 1,
        "categoryId": 2,
        "categoryName": "Beverages",
        "productName": "Iced Lemon Tea",
        "description": "Chilled citrus infused black tea",
        "productImageStorageKey": null,
        "sellingPrice": 65.50,
        "taxId": 1,
        "taxPercentage": 5.0,
        "hsnCode": "0902",
        "isAvailable": true,
        "isActive": true,
        "createdAtUtc": "2026-11-13T10:00:00.000Z",
      };

      final model = ProductModel.fromJson(json);

      expect(model.id, 10);
      expect(model.productName, "Iced Lemon Tea");
      expect(model.categoryName, "Beverages");
      expect(model.sellingPrice, 65.50);
      expect(model.taxPercentage, 5.0);
      expect(model.isAvailable, true);

      final outJson = model.toJson();
      expect(outJson["productId"], 10);
      expect(outJson["sellingPrice"], 65.50);
    });

    test("ProductModel SQLite roundtrip preserves columns", () {
      final original = ProductModel(
        id: 5,
        productGuid: "guid-12345",
        companyId: 1,
        categoryId: 3,
        categoryName: "Snacks",
        productName: "Grilled Veg Sandwich",
        description: "Toasted sandwich with fresh veggies",
        sellingPrice: 110.0,
        taxPercentage: 5.0,
        hsnCode: "1905",
        isAvailable: true,
        isActive: true,
        createdAtUtc: DateTime.utc(2026, 11, 13, 10, 0),
      );

      final sqliteMap = original.toSqlite();
      expect(sqliteMap["ProductId"], 5);
      expect(sqliteMap["SellingPrice"], 110.0);
      expect(sqliteMap["IsAvailable"], 1);

      final roundtrip = ProductModel.fromSqlite(sqliteMap, categoryName: "Snacks");
      expect(roundtrip.id, original.id);
      expect(roundtrip.productName, original.productName);
      expect(roundtrip.sellingPrice, original.sellingPrice);
      expect(roundtrip.isAvailable, true);
    });

    test("CategoryModel deserializes and serializes properly", () {
      final json = {
        "categoryId": 1,
        "categoryGuid": "cat-guid-1",
        "categoryName": "Coffee",
        "description": "Hot and iced coffees",
        "displayOrder": 1,
        "isActive": true,
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 1);
      expect(cat.categoryName, "Coffee");
      expect(cat.displayOrder, 1);
      expect(cat.isActive, true);
    });
  });
}

