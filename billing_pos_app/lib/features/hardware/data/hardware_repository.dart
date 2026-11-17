import "dart:async";
import "dart:convert";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "package:billing_pos_app/core/storage/storage_service.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../models/printer_model.dart";
import "../services/esc_pos_generator.dart";

final hardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return HardwareRepository(dioClient, storageService);
});

class HardwareRepository {
  final DioClient _dioClient;
  final IStorageService? _storageService;

  HardwareRepository(this._dioClient, [this._storageService]);

  Future<ApiResponse<List<PrinterConfigurationModel>>> getPrinters() async {
    // 1. FAST LOCAL-FIRST: Load cached printers from storage immediately (< 1ms)
    final localList = await _loadLocalPrinters();

    // 2. Background sync from server (unblocking UI!)
    unawaited(_syncRemotePrinters());

    return ApiResponse<List<PrinterConfigurationModel>>(
      success: true,
      message: "Loaded from local storage",
      data: localList,
    );
  }

  Future<void> _syncRemotePrinters() async {
    try {
      if (await _dioClient.isOfflineMode) return;
      final response = await _dioClient.get(ApiEndpoints.hardwarePrinters);
      if (response.success && response.data != null) {
        final list = (response.data as List)
            .map((item) => PrinterConfigurationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          await _saveLocalPrinters(list);
        }
      }
    } catch (_) {}
  }

  Future<ApiResponse<PrinterConfigurationModel?>> getDefaultPrinter() async {
    final printers = await _loadLocalPrinters();
    final defaultP = printers.isEmpty
        ? null
        : printers.firstWhere((p) => p.isDefault, orElse: () => printers.first);
    return ApiResponse<PrinterConfigurationModel?>(
      success: true,
      message: "Default printer retrieved",
      data: defaultP,
    );
  }

  Future<ApiResponse<PrinterConfigurationModel>> createPrinter(PrinterConfigurationModel config) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.hardwarePrinters,
        data: config.toJson(),
      );
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        await _appendLocalPrinter(model);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    // Offline save fallback
    final assignedId = DateTime.now().millisecondsSinceEpoch % 100000;
    final offlineModel = config.copyWith(id: assignedId);
    await _appendLocalPrinter(offlineModel);
    return ApiResponse<PrinterConfigurationModel>(
      success: true,
      message: "Printer saved locally",
      data: offlineModel,
    );
  }

  Future<ApiResponse<PrinterConfigurationModel>> updatePrinter(int id, PrinterConfigurationModel config) async {
    try {
      final response = await _dioClient.put(
        "${ApiEndpoints.hardwarePrinters}/$id",
        data: config.toJson(),
      );
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        await _updateLocalPrinter(id, model);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    await _updateLocalPrinter(id, config);
    return ApiResponse<PrinterConfigurationModel>(
      success: true,
      message: "Printer updated locally",
      data: config,
    );
  }

  Future<ApiResponse<void>> deletePrinter(int id) async {
    try {
      final response = await _dioClient.delete("${ApiEndpoints.hardwarePrinters}/$id");
      if (response.success) {
        await _deleteLocalPrinter(id);
        return ApiResponse<void>(success: true, message: "Printer deleted");
      }
    } catch (_) {}

    await _deleteLocalPrinter(id);
    return ApiResponse<void>(success: true, message: "Printer deleted locally");
  }

  Future<ApiResponse<PrinterConfigurationModel>> setDefaultPrinter(int id) async {
    try {
      final response = await _dioClient.post("${ApiEndpoints.hardwarePrinters}/$id/set-default");
      if (response.success && response.data != null) {
        final model = PrinterConfigurationModel.fromJson(response.data as Map<String, dynamic>);
        await _setDefaultLocalPrinter(id);
        return ApiResponse<PrinterConfigurationModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    final updated = await _setDefaultLocalPrinter(id);
    return ApiResponse<PrinterConfigurationModel>(
      success: true,
      message: "Default printer set locally",
      data: updated,
    );
  }

  Future<ApiResponse<TestPrintResultModel>> generateTestPrint({int? printerId}) async {
    try {
      final queryParams = printerId != null ? {"printerId": printerId} : null;
      final response = await _dioClient.post(
        ApiEndpoints.hardwareTestPrint,
        queryParameters: queryParams,
      );
      if (response.success && response.data != null) {
        final model = TestPrintResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<TestPrintResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    // Pure Dart local receipt generator fallback
    final printers = await _loadLocalPrinters();
    final p = (printerId != null
        ? printers.firstWhere((x) => x.id == printerId, orElse: () => printers.first)
        : printers.first);
    final rawBytes = EscPosGenerator.buildTestReceipt(p);
    final preview = """
================================
         TEST PRINT
   PulsePOS / LitePOS System
   Date: ${DateTime.now().toLocal().toString().split('.')[0]}
--------------------------------
Printer Name: ${p.printerName}
Connection:   ${p.connectionType.name.toUpperCase()}
Paper Size:   ${p.paperSize == PrinterPaperSize.mm58 ? '58mm' : '80mm'}
Auto-Cut:     ${p.autoCutReceipt ? 'Enabled' : 'Disabled'}
Cash Drawer:  ${p.openCashDrawer ? 'Enabled' : 'Disabled'}
--------------------------------
Thermal Printer Working Properly!
          Thank You!
================================
""";

    return ApiResponse<TestPrintResultModel>(
      success: true,
      message: "Test receipt generated in Dart",
      data: TestPrintResultModel(
        printerName: p.printerName,
        paperSize: p.paperSize,
        base64EscPosBytes: base64Encode(rawBytes),
        byteCount: rawBytes.length,
        plainTextPreview: preview,
        generatedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }

  Future<ApiResponse<CashDrawerCommandModel>> openCashDrawer() async {
    try {
      final response = await _dioClient.post(ApiEndpoints.hardwareOpenDrawer);
      if (response.success && response.data != null) {
        final model = CashDrawerCommandModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<CashDrawerCommandModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    return ApiResponse<CashDrawerCommandModel>(
      success: true,
      message: "Cash drawer command generated",
      data: CashDrawerCommandModel(
        commandName: "Standard ESC/POS Pulse",
        base64EscPosBytes: base64Encode(EscPosGenerator.openCashDrawer),
        hexString: "1B 70 00 19 FA",
      ),
    );
  }

  Future<ApiResponse<ReceiptPrintResultModel>> getInvoiceReceipt(int invoiceId, {int? printerId}) async {
    try {
      final queryParams = printerId != null ? {"printerId": printerId} : null;
      final response = await _dioClient.get(
        "${ApiEndpoints.hardwareReceipt}/$invoiceId",
        queryParameters: queryParams,
      );
      if (response.success && response.data != null) {
        final model = ReceiptPrintResultModel.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<ReceiptPrintResultModel>(
          success: true,
          message: response.message,
          data: model,
        );
      }
    } catch (_) {}

    return ApiResponse<ReceiptPrintResultModel>(
      success: false,
      message: "Invoice receipt generation unavailable offline.",
    );
  }

  // ─── LOCAL STORAGE HELPERS ─────────────────────────────────────────

  Future<List<PrinterConfigurationModel>> _loadLocalPrinters() async {
    try {
      final jsonStr = await _storageService?.read("cached_printers_list");
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        final list = decoded.map((e) => PrinterConfigurationModel.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    const defaultPrinter = PrinterConfigurationModel(
      id: 1,
      printerName: "Counter Thermal 80mm",
      connectionType: PrinterConnectionType.network,
      ipAddress: "192.168.1.100",
      port: 9100,
      paperSize: PrinterPaperSize.mm80,
      characterColumns: 48,
      isDefault: true,
      autoCutReceipt: true,
      openCashDrawer: true,
      printQrCode: true,
    );
    final initialList = [defaultPrinter];
    await _saveLocalPrinters(initialList);
    return initialList;
  }

  Future<void> _saveLocalPrinters(List<PrinterConfigurationModel> list) async {
    try {
      final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storageService?.write("cached_printers_list", jsonStr);
    } catch (_) {}
  }

  Future<void> _appendLocalPrinter(PrinterConfigurationModel item) async {
    final list = await _loadLocalPrinters();
    final updated = List<PrinterConfigurationModel>.from(list);
    if (item.isDefault) {
      for (var i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }
    updated.add(item);
    await _saveLocalPrinters(updated);
  }

  Future<void> _updateLocalPrinter(int id, PrinterConfigurationModel item) async {
    final list = await _loadLocalPrinters();
    final updated = List<PrinterConfigurationModel>.from(list);
    final idx = updated.indexWhere((p) => p.id == id);
    if (idx != -1) {
      if (item.isDefault) {
        for (var i = 0; i < updated.length; i++) {
          updated[i] = updated[i].copyWith(isDefault: false);
        }
      }
      updated[idx] = item;
    }
    await _saveLocalPrinters(updated);
  }

  Future<void> _deleteLocalPrinter(int id) async {
    final list = await _loadLocalPrinters();
    final updated = list.where((p) => p.id != id).toList();
    if (updated.isNotEmpty && !updated.any((p) => p.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }
    await _saveLocalPrinters(updated);
  }

  Future<PrinterConfigurationModel?> _setDefaultLocalPrinter(int id) async {
    final list = await _loadLocalPrinters();
    final updated = <PrinterConfigurationModel>[];
    PrinterConfigurationModel? defaultP;
    for (final p in list) {
      if (p.id == id) {
        final target = p.copyWith(isDefault: true);
        defaultP = target;
        updated.add(target);
      } else {
        updated.add(p.copyWith(isDefault: false));
      }
    }
    await _saveLocalPrinters(updated);
    return defaultP;
  }
}
