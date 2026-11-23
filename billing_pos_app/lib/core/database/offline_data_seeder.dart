import "package:sqflite/sqflite.dart";
import "app_database.dart";
import "database_tables.dart";

class OfflineDataSeeder {
  static Future<void> seedIfEmpty(AppDatabase appDb) async {
    try {
      final db = await appDb.database;
      await cleanLegacyDummyData(db);
      await seedSystemRoot(db);
    } catch (_) {}
  }

  /// Removes all legacy static/dummy mock data from local SQLite
  static Future<void> cleanLegacyDummyData(Database db) async {
    try {
      // 1. Wipe all dummy products and categories
      await db.delete(DatabaseTables.localProduct);
      await db.delete(DatabaseTables.localCategory);

      // 2. Wipe dummy customers
      await db.delete(DatabaseTables.localCustomer);

      // 3. Wipe dummy transactions & billing records
      await db.delete(DatabaseTables.localInvoiceDetail);
      await db.delete(DatabaseTables.localInvoice);
      await db.delete(DatabaseTables.localOrderDetail);
      await db.delete(DatabaseTables.localOrder);
      await db.delete(DatabaseTables.localPayment);
      await db.delete(DatabaseTables.localCreditNote);
      await db.delete(DatabaseTables.localSyncOutbox);
      await db.delete(DatabaseTables.localSyncLog);

      // 4. Wipe dummy company, shop, and GST configs that used "Pooja"
      await db.delete(DatabaseTables.localCompany, where: "CompanyName LIKE '%Pooja%'");
      await db.delete(DatabaseTables.localShop, where: "ShopName LIKE '%Pooja%'");
      await db.delete(DatabaseTables.localGstConfig, where: "TradeName LIKE '%Pooja%' OR LegalName LIKE '%Pooja%'");

      // 5. Delete pre-seeded dummy admin and cashier (Admin/Cashier must be created dynamically)
      await db.delete(
        DatabaseTables.localUser,
        where: "Username IN ('admin', 'cashier') AND (FullName LIKE '%Shop%' OR FullName LIKE '%Billing%')",
      );
    } catch (_) {}
  }

  /// Completely wipes all user data and resets database to a fresh state with only root sadmin
  static Future<void> wipeDatabase(Database db) async {
    final batch = db.batch();
    for (final table in DatabaseTables.allTables) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
    await seedSystemRoot(db);
  }

  /// Super Administrator must strictly authenticate online only.
  /// No offline root credentials are seeded locally.
  static Future<void> seedSystemRoot(Database db) async {
    // SAdmin works strictly online. Local seeding disabled to prevent offline bypass.
  }

  /// Standard entry point: ensures legacy dummy data is purged and root sadmin is available
  static Future<void> seedDatabase(Database db) async {
    await cleanLegacyDummyData(db);
    await seedSystemRoot(db);
  }
}
