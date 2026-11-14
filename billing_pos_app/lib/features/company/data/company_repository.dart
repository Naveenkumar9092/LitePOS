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
    final response = await _dioClient.post<CompanyProfileModel>(
      ApiEndpoints.companySetup,
      data: request,
      fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      await _cacheProfileLocally(response.data!);
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<CompanyProfileModel> getProfile() async {
    try {
      final response = await _dioClient.get<CompanyProfileModel>(
        ApiEndpoints.companyProfile,
        fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.data != null) {
        await _cacheProfileLocally(response.data!);
        return response.data!;
      }
    } catch (_) {
      // Offline fallback: load from local SQLite
      final local = await getLocalProfile();
      if (local != null) return local;
      rethrow;
    }
    throw Exception("Company profile not found.");
  }

  Future<CompanyProfileModel> updateProfile(Map<String, dynamic> request) async {
    final response = await _dioClient.put<CompanyProfileModel>(
      ApiEndpoints.companyProfile,
      data: request,
      fromJson: (data) => CompanyProfileModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.data != null) {
      await _cacheProfileLocally(response.data!);
      return response.data!;
    }
    throw Exception(response.message);
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

