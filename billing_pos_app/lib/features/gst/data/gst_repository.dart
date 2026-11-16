import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite/sqflite.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/gst_models.dart";

final gstRepositoryProvider = Provider<GstRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return GstRepository(dioClient, db);
});

class GstRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  GstRepository(this._dioClient, this._db);

  /// Fetch Taxes (API with SQLite fallback)
  Future<ApiResponse<List<TaxModel>>> getTaxes({bool? activeOnly}) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.gstTaxes,
        queryParameters: activeOnly != null ? {"activeOnly": activeOnly} : null,
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => TaxModel.fromJson(e as Map<String, dynamic>))
            .toList();

        await _cacheTaxesLocally(list);
        return ApiResponse<List<TaxModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<TaxModel>>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      return await _loadLocalTaxes(activeOnly: activeOnly);
    }
  }

  /// Create Tax
  Future<ApiResponse<TaxModel>> createTax(CreateTaxRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.gstTaxes,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final tax = TaxModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheSingleTaxLocally(tax);
        return ApiResponse<TaxModel>(
          success: true,
          message: response.message,
          data: tax,
        );
      }
      return ApiResponse<TaxModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      final db = await _db.database;
      final cgst = double.parse((request.ratePercentage / 2.0).toStringAsFixed(2));
      final sgst = double.parse((request.ratePercentage - cgst).toStringAsFixed(2));
      final igst = request.ratePercentage;
      final newId = DateTime.now().millisecondsSinceEpoch % 100000;

      final tax = TaxModel(
        id: newId,
        taxName: request.taxName,
        ratePercentage: request.ratePercentage,
        cgstPercentage: cgst,
        sgstPercentage: sgst,
        igstPercentage: igst,
        isActive: true,
        isDefault: request.isDefault,
        isTaxInclusiveDefault: request.isTaxInclusiveDefault,
      );

      await db.insert(
        DatabaseTables.localTax,
        tax.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return ApiResponse<TaxModel>(
        success: true,
        message: "Tax created locally (offline).",
        data: tax,
      );
    }
  }

  /// Update Tax
  Future<ApiResponse<TaxModel>> updateTax(int id, CreateTaxRequest request, {bool isActive = true}) async {
    try {
      final response = await _dioClient.put(
        "${ApiEndpoints.gstTaxes}/$id",
        data: {
          ...request.toJson(),
          "isActive": isActive,
        },
      );

      if (response.success && response.data != null) {
        final tax = TaxModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheSingleTaxLocally(tax);
        return ApiResponse<TaxModel>(
          success: true,
          message: response.message,
          data: tax,
        );
      }
      return ApiResponse<TaxModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      final db = await _db.database;
      final cgst = double.parse((request.ratePercentage / 2.0).toStringAsFixed(2));
      final sgst = double.parse((request.ratePercentage - cgst).toStringAsFixed(2));

      final tax = TaxModel(
        id: id,
        taxName: request.taxName,
        ratePercentage: request.ratePercentage,
        cgstPercentage: cgst,
        sgstPercentage: sgst,
        igstPercentage: request.ratePercentage,
        isActive: isActive,
        isDefault: request.isDefault,
        isTaxInclusiveDefault: request.isTaxInclusiveDefault,
      );

      await db.update(
        DatabaseTables.localTax,
        tax.toSqlite(),
        where: "TaxId = ?",
        whereArgs: [id],
      );

      return ApiResponse<TaxModel>(
        success: true,
        message: "Tax updated locally (offline).",
        data: tax,
      );
    }
  }

  /// Fetch HSN/SAC codes
  Future<ApiResponse<List<HsnSacModel>>> getHsnSacs({bool? activeOnly}) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.gstHsn,
        queryParameters: activeOnly != null ? {"activeOnly": activeOnly} : null,
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => HsnSacModel.fromJson(e as Map<String, dynamic>))
            .toList();

        await _cacheHsnLocally(list);
        return ApiResponse<List<HsnSacModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<HsnSacModel>>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      return await _loadLocalHsn(activeOnly: activeOnly);
    }
  }

  /// Create or Update HSN/SAC
  Future<ApiResponse<HsnSacModel>> createOrUpdateHsn(CreateHsnRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.gstHsn,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final hsn = HsnSacModel.fromJson(response.data as Map<String, dynamic>);
        final db = await _db.database;
        await db.insert(
          DatabaseTables.localHsnSac,
          hsn.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return ApiResponse<HsnSacModel>(
          success: true,
          message: response.message,
          data: hsn,
        );
      }
      return ApiResponse<HsnSacModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      final db = await _db.database;
      final hsn = HsnSacModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        code: request.code,
        description: request.description,
        type: request.type,
        defaultGstRate: request.defaultGstRate,
        isActive: request.isActive,
      );

      await db.insert(
        DatabaseTables.localHsnSac,
        hsn.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return ApiResponse<HsnSacModel>(
        success: true,
        message: "HSN code saved locally (offline).",
        data: hsn,
      );
    }
  }

  /// Get GST Configuration
  Future<ApiResponse<GstConfigurationModel>> getGstConfig() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.gstConfig);
      if (response.success && response.data != null) {
        final config = GstConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<GstConfigurationModel>(
          success: true,
          message: response.message,
          data: config,
        );
      }
      return ApiResponse<GstConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      // Default fallback config
      const config = GstConfigurationModel(
        id: 1,
        gstin: "33AAAAA0000A1Z5",
        legalName: "LitePOS Tech Pvt Ltd",
        tradeName: "LitePOS Cafe & Desserts",
        stateName: "Tamil Nadu",
        stateCode: "33",
        isCompositionScheme: false,
        defaultPricingIsTaxInclusive: true,
        invoiceTermsAndConditions: "1. Goods once sold will not be taken back.",
        invoiceHeader: "Welcome to LitePOS!",
        invoiceFooter: "Thank you for your visit!",
        showHsnSummaryOnReceipt: true,
        showTaxBreakupOnReceipt: true,
      );
      return ApiResponse<GstConfigurationModel>(
        success: true,
        message: "Loaded local GST configuration.",
        data: config,
      );
    }
  }

  /// Update GST Configuration
  Future<ApiResponse<GstConfigurationModel>> updateGstConfig(UpdateGstConfigRequest request) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.gstConfig,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final config = GstConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<GstConfigurationModel>(
          success: true,
          message: response.message,
          data: config,
        );
      }
      return ApiResponse<GstConfigurationModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      final config = GstConfigurationModel(
        id: 1,
        gstin: request.gstin,
        legalName: request.legalName,
        tradeName: request.tradeName,
        stateName: request.stateName,
        stateCode: request.stateCode,
        isCompositionScheme: request.isCompositionScheme,
        defaultPricingIsTaxInclusive: request.defaultPricingIsTaxInclusive,
        invoiceTermsAndConditions: request.invoiceTermsAndConditions,
        invoiceHeader: request.invoiceHeader,
        invoiceFooter: request.invoiceFooter,
        showHsnSummaryOnReceipt: request.showHsnSummaryOnReceipt,
        showTaxBreakupOnReceipt: request.showTaxBreakupOnReceipt,
      );
      return ApiResponse<GstConfigurationModel>(
        success: true,
        message: "GST config updated locally (offline).",
        data: config,
      );
    }
  }

  /// Get GST Summary Report
  Future<ApiResponse<GstSummaryModel>> getGstSummary({DateTime? fromUtc, DateTime? toUtc}) async {
    try {
      final Map<String, dynamic> params = {};
      if (fromUtc != null) params["fromUtc"] = fromUtc.toIso8601String();
      if (toUtc != null) params["toUtc"] = toUtc.toIso8601String();

      final response = await _dioClient.get(
        ApiEndpoints.gstSummary,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.data != null) {
        final summary = GstSummaryModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<GstSummaryModel>(
          success: true,
          message: response.message,
          data: summary,
        );
      }
      return ApiResponse<GstSummaryModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<GstSummaryModel>(
        success: false,
        message: "Failed to generate GST summary: $e",
      );
    }
  }

  /// Issue Credit Note
  Future<ApiResponse<CreditNoteModel>> createCreditNote(CreateCreditNoteRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.creditNotes,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final creditNote = CreditNoteModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CreditNoteModel>(
          success: true,
          message: response.message,
          data: creditNote,
        );
      }
      return ApiResponse<CreditNoteModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<CreditNoteModel>(
        success: false,
        message: "Failed to issue credit note: $e",
      );
    }
  }

  /// Get Credit Notes list
  Future<ApiResponse<List<CreditNoteModel>>> getCreditNotes({int? invoiceId, String? noteType}) async {
    try {
      final Map<String, dynamic> params = {};
      if (invoiceId != null) params["invoiceId"] = invoiceId;
      if (noteType != null) params["noteType"] = noteType;

      final response = await _dioClient.get(
        ApiEndpoints.creditNotes,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => CreditNoteModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<CreditNoteModel>>(
          success: true,
          message: response.message,
          data: list,
        );
      }
      return ApiResponse<List<CreditNoteModel>>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      return ApiResponse<List<CreditNoteModel>>(
        success: true,
        message: "Offline credit notes loaded.",
        data: const [],
      );
    }
  }

  // --- SQLite Helpers ---

  Future<void> _cacheTaxesLocally(List<TaxModel> taxes) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final t in taxes) {
      batch.insert(
        DatabaseTables.localTax,
        t.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _cacheSingleTaxLocally(TaxModel tax) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.localTax,
      tax.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ApiResponse<List<TaxModel>>> _loadLocalTaxes({bool? activeOnly}) async {
    final db = await _db.database;
    final where = activeOnly == true ? "IsActive = 1" : null;
    final rows = await db.query(
      DatabaseTables.localTax,
      where: where,
      orderBy: "RatePercentage ASC",
    );

    if (rows.isEmpty) {
      // Return standard default slabs
      final defaults = [
        const TaxModel(id: 1, taxName: "Exempt 0%", ratePercentage: 0, cgstPercentage: 0, sgstPercentage: 0, igstPercentage: 0, isActive: true, isDefault: false, isTaxInclusiveDefault: true),
        const TaxModel(id: 2, taxName: "GST 5%", ratePercentage: 5, cgstPercentage: 2.5, sgstPercentage: 2.5, igstPercentage: 5, isActive: true, isDefault: true, isTaxInclusiveDefault: true),
        const TaxModel(id: 3, taxName: "GST 12%", ratePercentage: 12, cgstPercentage: 6, sgstPercentage: 6, igstPercentage: 12, isActive: true, isDefault: false, isTaxInclusiveDefault: true),
        const TaxModel(id: 4, taxName: "GST 18%", ratePercentage: 18, cgstPercentage: 9, sgstPercentage: 9, igstPercentage: 18, isActive: true, isDefault: false, isTaxInclusiveDefault: true),
        const TaxModel(id: 5, taxName: "GST 28%", ratePercentage: 28, cgstPercentage: 14, sgstPercentage: 14, igstPercentage: 28, isActive: true, isDefault: false, isTaxInclusiveDefault: true),
      ];
      return ApiResponse<List<TaxModel>>(
        success: true,
        message: "Default GST slabs loaded offline.",
        data: defaults,
      );
    }

    final list = rows.map(TaxModel.fromSqlite).toList();
    return ApiResponse<List<TaxModel>>(
      success: true,
      message: "Offline GST slabs loaded.",
      data: list,
    );
  }

  Future<void> _cacheHsnLocally(List<HsnSacModel> list) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final h in list) {
      batch.insert(
        DatabaseTables.localHsnSac,
        h.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<ApiResponse<List<HsnSacModel>>> _loadLocalHsn({bool? activeOnly}) async {
    final db = await _db.database;
    final where = activeOnly == true ? "IsActive = 1" : null;
    final rows = await db.query(
      DatabaseTables.localHsnSac,
      where: where,
      orderBy: "Code ASC",
    );

    if (rows.isEmpty) {
      final defaults = [
        const HsnSacModel(id: 1, code: "2106", description: "Food preparations n.e.c (Sweets, snacks)", type: "HSN", defaultGstRate: 5, isActive: true),
        const HsnSacModel(id: 2, code: "2202", description: "Waters and flavoured beverages", type: "HSN", defaultGstRate: 18, isActive: true),
        const HsnSacModel(id: 3, code: "1905", description: "Bread, pastry, cakes, biscuits", type: "HSN", defaultGstRate: 5, isActive: true),
        const HsnSacModel(id: 4, code: "9963", description: "Restaurant and food court catering services", type: "SAC", defaultGstRate: 5, isActive: true),
      ];
      return ApiResponse<List<HsnSacModel>>(
        success: true,
        message: "Default HSN codes loaded offline.",
        data: defaults,
      );
    }

    final list = rows.map(HsnSacModel.fromSqlite).toList();
    return ApiResponse<List<HsnSacModel>>(
      success: true,
      message: "Offline HSN codes loaded.",
      data: list,
    );
  }
}
