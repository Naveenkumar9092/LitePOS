import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite/sqflite.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/database/app_database.dart";
import "../../../core/database/database_tables.dart";
import "../../../core/network/dio_client.dart";
import "../../../core/storage/storage_service.dart";
import "../models/company_model.dart";

final storageServiceProvider = Provider<IStorageService>((ref) {
  throw UnimplementedError();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DioClient(storageService);
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final appDb = ref.watch(appDatabaseProvider);
  return CompanyRepository(dioClient, appDb);
});

class CompanyRepository {
  final DioClient _dioClient;
  final AppDatabase _appDb;

  CompanyRepository(this._dioClient, this._appDb);

  Future<CompanyProfileModel> setupCompany(Map<String, dynamic> request) async {
    // 1. FAST LOCAL-FIRST: Save company in local SQLite
    final db = await _appDb.database;
    final maxIdRow = await db.rawQuery("SELECT MAX(CompanyId) as maxId FROM ${DatabaseTables.localCompany}");
    final maxId = (maxIdRow.first["maxId"] as num?)?.toInt() ?? 0;
    final newCompanyId = maxId > 0 ? maxId + 1 : 1;

    final companyModel = CompanyProfileModel(
      companyId: newCompanyId,
      companyName: request["companyName"]?.toString() ?? "Store",
      legalName: request["legalName"]?.toString() ?? request["companyName"]?.toString() ?? "Store",
      businessCategory: BusinessCategory.fromId((request["businessType"] as num?)?.toInt() ?? 1),
      email: request["email"]?.toString() ?? "contact@store.com",
      mobileNumber: request["mobileNumber"]?.toString() ?? "9876543210",
      website: request["website"]?.toString(),
      gstin: request["gstin"]?.toString(),
      pan: request["pan"]?.toString(),
      logoStorageKey: request["logoStorageKey"]?.toString(),
      isActive: true,
      shop: ShopModel(
        shopId: newCompanyId,
        companyId: newCompanyId,
        shopName: request["shopName"]?.toString() ?? request["companyName"]?.toString() ?? "Store",
        addressLine1: request["addressLine1"]?.toString() ?? "Main Store",
        city: request["city"]?.toString() ?? "City",
        state: request["state"]?.toString() ?? "Tamil Nadu",
        pincode: request["pincode"]?.toString() ?? "600001",
        country: request["country"]?.toString() ?? "India",
        contactNumber: request["contactNumber"]?.toString() ?? request["mobileNumber"]?.toString() ?? "9876543210",
        email: request["email"]?.toString() ?? "contact@store.com",
        timeZone: "Asia/Kolkata",
        currencyCode: "INR",
        isActive: true,
      ),
    );

    await _cacheProfileLocally(companyModel);

    // 2. Cloud sync if online
    if (!(await _dioClient.isOfflineMode)) {
      try {
        final response = await _dioClient.post<CompanyProfileModel>(
          ApiEndpoints.companySetup,
          data: request,
          fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
        ).timeout(const Duration(seconds: 4));

        if (response.data != null) {
          await _cacheProfileLocally(response.data!);
          return response.data!;
        }
      } catch (_) {}
    }

    return companyModel;
  }

  Future<CompanyProfileModel> getProfile() async {
    // 1. FAST LOCAL-FIRST: Check local SQLite profile
    final local = await getLocalProfile();
    if (local != null) {
      if (!(await _dioClient.isOfflineMode)) {
        unawaited(_syncRemoteProfile());
      }
      return local;
    }

    // 2. If SQLite was empty and online, fetch from remote
    if (!(await _dioClient.isOfflineMode)) {
      try {
        final response = await _dioClient.get<CompanyProfileModel>(
          ApiEndpoints.companyProfile,
          fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
        ).timeout(const Duration(seconds: 3));

        if (response.data != null) {
          await _cacheProfileLocally(response.data!);
          return response.data!;
        }
      } catch (_) {}
    }

    // 3. Fallback default profile so UI never crashes
    final defaultCompany = CompanyProfileModel(
      companyId: 1,
      companyName: "Pooja Sweets & Cafe",
      legalName: "Pooja Sweets & Cafe",
      businessCategory: BusinessCategory.cafe,
      email: "contact@poojasweets.com",
      mobileNumber: "9876543210",
      isActive: true,
      shop: ShopModel(
        shopId: 1,
        companyId: 1,
        shopName: "Pooja Sweets & Cafe",
        addressLine1: "Counter 01",
        city: "City",
        state: "Tamil Nadu",
        pincode: "600001",
        country: "India",
        contactNumber: "9876543210",
        email: "contact@store.com",
        timeZone: "Asia/Kolkata",
        currencyCode: "INR",
        isActive: true,
      ),
    );
    await _cacheProfileLocally(defaultCompany);
    return defaultCompany;
  }

  Future<void> _syncRemoteProfile() async {
    try {
      final response = await _dioClient.get<CompanyProfileModel>(
        ApiEndpoints.companyProfile,
        fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
      ).timeout(const Duration(seconds: 3));

      if (response.data != null) {
        await _cacheProfileLocally(response.data!);
      }
    } catch (_) {}
  }

  Future<CompanyProfileModel> updateProfile(Map<String, dynamic> request) async {
    // 1. FAST LOCAL-FIRST: Update local SQLite company profile immediately
    final db = await _appDb.database;
    final existing = await getLocalProfile();
    final companyId = existing?.companyId ?? 1;

    final updateData = <String, dynamic>{
      if (request["companyName"] != null) "CompanyName": request["companyName"],
      if (request["legalName"] != null) "LegalName": request["legalName"],
      if (request["businessType"] != null) "BusinessType": request["businessType"],
      if (request["gstin"] != null) "GSTIN": request["gstin"],
      if (request["pan"] != null) "PAN": request["pan"],
      if (request["email"] != null) "Email": request["email"],
      if (request["mobileNumber"] != null) "MobileNumber": request["mobileNumber"],
      if (request["website"] != null) "Website": request["website"],
      if (request["logoStorageKey"] != null) "LogoStorageKey": request["logoStorageKey"],
    };

    if (updateData.isNotEmpty) {
      final count = await db.update(
        DatabaseTables.localCompany,
        updateData,
        where: "CompanyId = ?",
        whereArgs: [companyId],
      );
      if (count == 0) {
        // If row didn't exist yet, insert it
        updateData["CompanyId"] = companyId;
        updateData["IsActive"] = 1;
        updateData["CreatedAtUTC"] = DateTime.now().toUtc().toIso8601String();
        await db.insert(
          DatabaseTables.localCompany,
          updateData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 2. Cloud sync if online
    if (!(await _dioClient.isOfflineMode)) {
      try {
        final response = await _dioClient.put<CompanyProfileModel>(
          ApiEndpoints.companyProfile,
          data: request,
          fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
        ).timeout(const Duration(seconds: 4));

        if (response.data != null) {
          await _cacheProfileLocally(response.data!);
          return response.data!;
        }
      } catch (_) {
        // Offline / server error: local SQLite update already succeeded!
      }
    }

    final updated = await getLocalProfile();
    if (updated != null) {
      return updated;
    }

    return CompanyProfileModel(
      companyId: companyId,
      companyName: request["companyName"]?.toString() ?? "PulsePOS Store",
      legalName: request["legalName"]?.toString() ?? "PulsePOS Store",
      businessCategory: BusinessCategory.cafe,
      email: request["email"]?.toString() ?? "contact@store.com",
      mobileNumber: request["mobileNumber"]?.toString() ?? "9876543210",
      logoStorageKey: request["logoStorageKey"]?.toString(),
      isActive: true,
    );
  }

  Future<List<CompanyProfileModel>> getAllCompanies() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(
        DatabaseTables.localCompany,
        where: "IsActive = 1",
        orderBy: "CompanyName ASC",
      );
      final List<CompanyProfileModel> list = [];
      for (final r in rows) {
        final cMap = Map<String, dynamic>.from(r);
        final shops = await db.query(
          DatabaseTables.localShop,
          where: "CompanyId = ?",
          whereArgs: [cMap["CompanyId"]],
          limit: 1,
        );
        if (shops.isNotEmpty) {
          cMap["shop"] = Map<String, dynamic>.from(shops.first);
        }
        list.add(CompanyProfileModel.fromJson(cMap));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<CompanyProfileModel> createCompanyRecord({
    required String companyName,
    String? legalName,
    String? email,
    String? mobileNumber,
    String? city,
  }) async {
    final db = await _appDb.database;
    final maxIdRow = await db.rawQuery("SELECT MAX(CompanyId) as maxId FROM ${DatabaseTables.localCompany}");
    final maxId = (maxIdRow.first["maxId"] as num?)?.toInt() ?? 0;
    final newCompanyId = maxId > 0 ? maxId + 1 : 1;

    final companyModel = CompanyProfileModel(
      companyId: newCompanyId,
      companyName: companyName.trim(),
      legalName: legalName?.trim() ?? companyName.trim(),
      businessCategory: BusinessCategory.cafe,
      email: email?.trim() ?? "contact@store.com",
      mobileNumber: mobileNumber?.trim() ?? "9876543210",
      isActive: true,
      shop: ShopModel(
        shopId: newCompanyId,
        companyId: newCompanyId,
        shopName: companyName.trim(),
        addressLine1: city?.trim() ?? "Main Store",
        city: city?.trim() ?? "City",
        state: "Tamil Nadu",
        pincode: "600001",
        country: "India",
        contactNumber: mobileNumber?.trim() ?? "9876543210",
        email: email?.trim() ?? "contact@store.com",
        timeZone: "India Standard Time",
        currencyCode: "INR",
        isActive: true,
      ),
    );

    await _cacheProfileLocally(companyModel);
    return companyModel;
  }

  Future<CompanyProfileModel?> getLocalProfile() async {
    try {
      final db = await _appDb.database;
      final companies = await db.query(DatabaseTables.localCompany, limit: 1);
      if (companies.isEmpty) return null;

      final companyMap = Map<String, dynamic>.from(companies.first);
      final shops = await db.query(
        DatabaseTables.localShop,
        where: "CompanyId = ?",
        whereArgs: [companyMap["CompanyId"]],
        limit: 1,
      );

      if (shops.isNotEmpty) {
        companyMap["shop"] = Map<String, dynamic>.from(shops.first);
      }

      return CompanyProfileModel.fromJson(companyMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheProfileLocally(CompanyProfileModel profile) async {
    try {
      final db = await _appDb.database;
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseTables.localCompany,
          {
            "CompanyId": profile.companyId,
            "CompanyName": profile.companyName,
            "LegalName": profile.legalName,
            "BusinessType": profile.businessCategory.id,
            "GSTIN": profile.gstin,
            "PAN": profile.pan,
            "Email": profile.email,
            "MobileNumber": profile.mobileNumber,
            "Website": profile.website,
            "LogoStorageKey": profile.logoStorageKey,
            "IsActive": profile.isActive ? 1 : 0,
            "CreatedAtUTC": DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (profile.shop != null) {
          final s = profile.shop!;
          await txn.insert(
            DatabaseTables.localShop,
            {
              "ShopId": s.shopId,
              "CompanyId": s.companyId,
              "ShopName": s.shopName,
              "AddressLine1": s.addressLine1,
              "AddressLine2": s.addressLine2,
              "City": s.city,
              "State": s.state,
              "Pincode": s.pincode,
              "Country": s.country,
              "ContactNumber": s.contactNumber,
              "Email": s.email,
              "TimeZone": s.timeZone,
              "CurrencyCode": s.currencyCode,
              "IsActive": s.isActive ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (_) {
      // Ignore cache failure
    }
  }
}

