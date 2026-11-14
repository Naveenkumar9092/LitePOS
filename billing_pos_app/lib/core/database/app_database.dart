import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:sqflite_common_ffi_web/sqflite_ffi_web.dart";
import "database_tables.dart";

class AppDatabase {
  static const String _databaseName = "litepos_local.db";
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      try {
        databaseFactory = databaseFactoryFfiWeb;
        return await databaseFactoryFfiWeb.openDatabase(
          _databaseName,
          options: OpenDatabaseOptions(
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ),
        );
      } catch (_) {
        databaseFactory = databaseFactoryFfiWebNoWebWorker;
        return await databaseFactoryFfiWebNoWebWorker.openDatabase(
          _databaseName,
          options: OpenDatabaseOptions(
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ),
        );
      }
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute(DatabaseTables.createCompanyTable);
    batch.execute(DatabaseTables.createShopTable);
    batch.execute(DatabaseTables.createUserTable);
    batch.execute(DatabaseTables.createCategoryTable);
    batch.execute(DatabaseTables.createProductTable);
    batch.execute(DatabaseTables.createCustomerTable);
    batch.execute(DatabaseTables.createOrderTable);
    batch.execute(DatabaseTables.createOrderDetailTable);
    batch.execute(DatabaseTables.createInvoiceTable);
    batch.execute(DatabaseTables.createInvoiceDetailTable);
    batch.execute(DatabaseTables.createPaymentTable);
    batch.execute(DatabaseTables.createTaxTable);
    batch.execute(DatabaseTables.createHsnSacTable);
    batch.execute(DatabaseTables.createGstConfigTable);
    batch.execute(DatabaseTables.createCreditNoteTable);
    batch.execute(DatabaseTables.createSyncOutboxTable);
    batch.execute(DatabaseTables.createSyncLogTable);
    batch.execute(DatabaseTables.createDeviceStateTable);

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema migration handling for future versions
  }

  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
  }
}

