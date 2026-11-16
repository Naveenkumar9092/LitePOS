import "package:sqflite/sqflite.dart";
import "app_database.dart";
import "database_tables.dart";

class OfflineDataSeeder {
  static Future<void> seedIfEmpty(AppDatabase appDb) async {
    try {
      final db = await appDb.database;
      await seedDatabase(db);
    } catch (_) {}
  }

  static Future<void> seedDatabase(Database db) async {
    final nowIso = DateTime.now().toIso8601String();

    // 1. Company
    final companyCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localCompany}"),
    );
    if (companyCount == null || companyCount == 0) {
      await db.insert(
        DatabaseTables.localCompany,
        {
          "CompanyId": 1,
          "CompanyName": "Pooja Sweets & Cafe",
          "LegalName": "Pooja Retail & Food Enterprises Pvt Ltd",
          "BusinessType": 1,
          "GSTIN": "33AAAAA0000A1Z5",
          "PAN": "AAAAA0000A",
          "Email": "pooja@litepos.com",
          "MobileNumber": "9840123456",
          "Website": "https://litepos.local",
          "LogoStorageKey": "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=200&auto=format&fit=crop&q=80",
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Shop
    final shopCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localShop}"),
    );
    if (shopCount == null || shopCount == 0) {
      await db.insert(
        DatabaseTables.localShop,
        {
          "ShopId": 1,
          "CompanyId": 1,
          "ShopName": "Pooja Main Store",
          "AddressLine1": "42 Gandhi Road, T. Nagar",
          "AddressLine2": "Near Panagal Park",
          "City": "Chennai",
          "State": "Tamil Nadu",
          "Pincode": "600017",
          "Country": "India",
          "ContactNumber": "9840123456",
          "Email": "pooja@litepos.com",
          "TimeZone": "India Standard Time",
          "CurrencyCode": "INR",
          "IsActive": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 3. Local Users
    final userCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localUser}"),
    );
    if (userCount == null || userCount == 0) {
      final batch = db.batch();
      batch.insert(
        DatabaseTables.localUser,
        {
          "UserId": 1,
          "FullName": "Super Administrator",
          "Username": "sadmin",
          "Email": "sadmin@litepos.com",
          "MobileNumber": "9876543210",
          "RoleId": 1,
          "RoleName": "SAdmin",
          "IsActive": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        DatabaseTables.localUser,
        {
          "UserId": 2,
          "FullName": "Shop Administrator",
          "Username": "admin",
          "Email": "admin@litepos.com",
          "MobileNumber": "9876543211",
          "RoleId": 2,
          "RoleName": "Admin",
          "IsActive": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        DatabaseTables.localUser,
        {
          "UserId": 3,
          "FullName": "Billing Cashier",
          "Username": "cashier",
          "Email": "cashier@litepos.com",
          "MobileNumber": "9876543212",
          "RoleId": 3,
          "RoleName": "Cashier",
          "IsActive": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    }

    // 4. Categories
    final catCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localCategory}"),
    );
    if (catCount == null || catCount == 0) {
      final batch = db.batch();
      final defaultCategories = [
        {"CategoryId": 1, "CategoryGuid": "cat-sweets-01", "CategoryName": "Traditional Sweets", "Description": "Pure ghee sweets, laddus, katlis and festive specials", "DisplayOrder": 1, "IsActive": 1, "CreatedAtUTC": nowIso},
        {"CategoryId": 2, "CategoryGuid": "cat-bakery-02", "CategoryName": "Bakery & Snacks", "Description": "Freshly baked puffs, samosas, savouries and artisanal cookies", "DisplayOrder": 2, "IsActive": 1, "CreatedAtUTC": nowIso},
        {"CategoryId": 3, "CategoryGuid": "cat-beverage-03", "CategoryName": "Beverages", "Description": "South Indian filter coffee, royal badam milk, and fresh drinks", "DisplayOrder": 3, "IsActive": 1, "CreatedAtUTC": nowIso},
        {"CategoryId": 4, "CategoryGuid": "cat-pastry-04", "CategoryName": "Cakes & Pastries", "Description": "Rich Belgian chocolate pastries, brownies and celebration cakes", "DisplayOrder": 4, "IsActive": 1, "CreatedAtUTC": nowIso},
      ];
      for (final cat in defaultCategories) {
        batch.insert(DatabaseTables.localCategory, cat, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // 5. Products
    final prodCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localProduct}"),
    );
    if (prodCount == null || prodCount == 0) {
      final batch = db.batch();
      final defaultProducts = [
        {
          "ProductId": 1,
          "ProductGuid": "prod-gulab-01",
          "CompanyId": 1,
          "CategoryId": 1,
          "ProductName": "Gulab Jamun (2 Pcs)",
          "Description": "Melt-in-mouth soft mawa dumplings soaked in cardamom sugar syrup",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 60.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "21069099",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 2,
          "ProductGuid": "prod-kaju-02",
          "CompanyId": 1,
          "CategoryId": 1,
          "ProductName": "Kaju Katli (250g)",
          "Description": "Diamond silver leaf cashew fudge crafted from premium Goan cashews",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 250.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "21069099",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 3,
          "ProductGuid": "prod-mysore-03",
          "CompanyId": 1,
          "CategoryId": 1,
          "ProductName": "Mysore Pak (250g)",
          "Description": "Gently roasted besan infused with authentic aromatic pure desi ghee",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1505253758473-96b7015fcd40?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 180.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "21069099",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 4,
          "ProductGuid": "prod-laddu-04",
          "CompanyId": 1,
          "CategoryId": 1,
          "ProductName": "Motichoor Laddu (250g)",
          "Description": "Tiny golden gram flour pearls rolled with saffron and crushed pistachios",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 160.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "21069099",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 5,
          "ProductGuid": "prod-puff-05",
          "CompanyId": 1,
          "CategoryId": 2,
          "ProductName": "Paneer Butter Masala Puff",
          "Description": "Flaky golden puff pastry generously stuffed with spicy butter paneer",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 45.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "19059010",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 6,
          "ProductGuid": "prod-samosa-06",
          "CompanyId": 1,
          "CategoryId": 2,
          "ProductName": "Crispy Samosa (2 Pcs)",
          "Description": "Crisp crust filled with spiced potatoes, green peas and mint chutney",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 40.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "19059010",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 7,
          "ProductGuid": "prod-cookies-07",
          "CompanyId": 1,
          "CategoryId": 2,
          "ProductName": "Butter Pista Cookies (Pack)",
          "Description": "Crispy crumbly bakery biscuits loaded with salted butter and roasted pistachios",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 120.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "19053100",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 8,
          "ProductGuid": "prod-milk-08",
          "CompanyId": 1,
          "CategoryId": 3,
          "ProductName": "Royal Badam Milk",
          "Description": "Creamy almond saffron milk infused with green cardamom and rose petals",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1550547660-d9450f859349?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 70.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "22029990",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 9,
          "ProductGuid": "prod-coffee-09",
          "CompanyId": 1,
          "CategoryId": 3,
          "ProductName": "Filter Coffee",
          "Description": "Authentic aromatic freshly brewed South Indian chicory blend filter coffee",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 30.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "09012190",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
        {
          "ProductId": 10,
          "ProductGuid": "prod-pastry-10",
          "CompanyId": 1,
          "CategoryId": 4,
          "ProductName": "Belgian Chocolate Pastry",
          "Description": "Rich chocolate sponge layered with smooth Belgian dark chocolate mousse",
          "ProductImageStorageKey": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop&q=80",
          "SellingPrice": 95.00,
          "TaxId": 1,
          "TaxPercentage": 5.0,
          "HSNCode": "19059010",
          "IsAvailable": 1,
          "IsActive": 1,
          "CreatedAtUTC": nowIso,
        },
      ];

      for (final prod in defaultProducts) {
        batch.insert(DatabaseTables.localProduct, prod, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // 6. Taxes
    final taxCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localTax}"),
    );
    if (taxCount == null || taxCount == 0) {
      final batch = db.batch();
      batch.insert(
        DatabaseTables.localTax,
        {"TaxId": 1, "TaxName": "GST 5%", "RatePercentage": 5.0, "CgstPercentage": 2.5, "SgstPercentage": 2.5, "IgstPercentage": 5.0, "IsActive": 1, "IsDefault": 1, "IsTaxInclusiveDefault": 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        DatabaseTables.localTax,
        {"TaxId": 2, "TaxName": "GST 12%", "RatePercentage": 12.0, "CgstPercentage": 6.0, "SgstPercentage": 6.0, "IgstPercentage": 12.0, "IsActive": 1, "IsDefault": 0, "IsTaxInclusiveDefault": 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        DatabaseTables.localTax,
        {"TaxId": 3, "TaxName": "GST 18%", "RatePercentage": 18.0, "CgstPercentage": 9.0, "SgstPercentage": 9.0, "IgstPercentage": 18.0, "IsActive": 1, "IsDefault": 0, "IsTaxInclusiveDefault": 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    }

    // 7. Customers
    final custCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localCustomer}"),
    );
    if (custCount == null || custCount == 0) {
      final batch = db.batch();
      batch.insert(
        DatabaseTables.localCustomer,
        {"CustomerId": 1, "CustomerGuid": "cust-01", "CustomerName": "Walk-in Customer", "MobileNumber": "9876543200", "Email": "walkin@poojasweets.com", "IsActive": 1, "CreatedAtUTC": nowIso},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        DatabaseTables.localCustomer,
        {"CustomerId": 2, "CustomerGuid": "cust-02", "CustomerName": "Karthik Raja", "MobileNumber": "9876543201", "Email": "karthik@example.com", "IsActive": 1, "CreatedAtUTC": nowIso},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    }

    // 8. GST Config
    final gstCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localGstConfig}"),
    );
    if (gstCount == null || gstCount == 0) {
      await db.insert(
        DatabaseTables.localGstConfig,
        {
          "ConfigId": 1,
          "GSTIN": "33AAAAA0000A1Z5",
          "LegalName": "Pooja Retail & Food Enterprises Pvt Ltd",
          "TradeName": "Pooja Sweets & Cafe",
          "StateName": "Tamil Nadu",
          "StateCode": "33",
          "IsCompositionScheme": 0,
          "DefaultPricingIsTaxInclusive": 1,
          "InvoiceHeader": "Welcome to Pooja Sweets & Cafe",
          "InvoiceFooter": "Thank you for shopping at Pooja! Visit again.",
          "ShowHsnSummaryOnReceipt": 1,
          "ShowTaxBreakupOnReceipt": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
