import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/hardware_repository.dart";
import "../models/printer_model.dart";

class HardwareState {
  final bool isLoading;
  final bool isPrinting;
  final List<PrinterConfigurationModel> printers;
  final PrinterConfigurationModel? defaultPrinter;
  final TestPrintResultModel? lastTestPrint;
  final CashDrawerCommandModel? lastDrawerCommand;
  final ReceiptPrintResultModel? lastReceiptResult;
  final String? errorMessage;
  final String? successMessage;

  const HardwareState({
    this.isLoading = false,
    this.isPrinting = false,
    this.printers = const [],
    this.defaultPrinter,
    this.lastTestPrint,
    this.lastDrawerCommand,
    this.lastReceiptResult,
    this.errorMessage,
    this.successMessage,
  });

  HardwareState copyWith({
    bool? isLoading,
    bool? isPrinting,
    List<PrinterConfigurationModel>? printers,
    PrinterConfigurationModel? defaultPrinter,
    TestPrintResultModel? lastTestPrint,
    CashDrawerCommandModel? lastDrawerCommand,
    ReceiptPrintResultModel? lastReceiptResult,
    String? errorMessage,
    String? successMessage,
    bool clearDefaultPrinter = false,
  }) {
    return HardwareState(
      isLoading: isLoading ?? this.isLoading,
      isPrinting: isPrinting ?? this.isPrinting,
      printers: printers ?? this.printers,
      defaultPrinter: clearDefaultPrinter ? null : (defaultPrinter ?? this.defaultPrinter),
      lastTestPrint: lastTestPrint ?? this.lastTestPrint,
      lastDrawerCommand: lastDrawerCommand ?? this.lastDrawerCommand,
      lastReceiptResult: lastReceiptResult ?? this.lastReceiptResult,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final hardwareNotifierProvider = StateNotifierProvider<HardwareNotifier, HardwareState>((ref) {
  final repository = ref.watch(hardwareRepositoryProvider);
  return HardwareNotifier(repository);
});

class HardwareNotifier extends StateNotifier<HardwareState> {
  final HardwareRepository _repository;

  HardwareNotifier(this._repository) : super(const HardwareState()) {
    loadPrinters();
  }

  Future<void> loadPrinters() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getPrinters();
      if (res.success && res.data != null) {
        final printers = res.data!;
        PrinterConfigurationModel? defaultP;
        for (final p in printers) {
          if (p.isDefault) {
            defaultP = p;
            break;
          }
        }
        defaultP ??= printers.isNotEmpty ? printers.first : null;

        state = state.copyWith(
          isLoading: false,
          printers: printers,
          defaultPrinter: defaultP,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to load thermal printers.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createPrinter(PrinterConfigurationModel config) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.createPrinter(config);
      if (res.success && res.data != null) {
        await loadPrinters();
        state = state.copyWith(
          successMessage: "Printer '${res.data!.printerName}' added successfully.",
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to create printer.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updatePrinter(int id, PrinterConfigurationModel config) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.updatePrinter(id, config);
      if (res.success && res.data != null) {
        await loadPrinters();
        state = state.copyWith(
          successMessage: "Printer '${res.data!.printerName}' updated successfully.",
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to update printer.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deletePrinter(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.deletePrinter(id);
      if (res.success) {
        await loadPrinters();
        state = state.copyWith(
          successMessage: "Printer deleted successfully.",
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to delete printer.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> setDefaultPrinter(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.setDefaultPrinter(id);
      if (res.success && res.data != null) {
        await loadPrinters();
        state = state.copyWith(
          successMessage: "'${res.data!.printerName}' set as default printer.",
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to set default printer.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<TestPrintResultModel?> testPrint({int? printerId}) async {
    state = state.copyWith(isPrinting: true, errorMessage: null);
    try {
      final res = await _repository.generateTestPrint(printerId: printerId);
      if (res.success && res.data != null) {
        state = state.copyWith(
          isPrinting: false,
          lastTestPrint: res.data,
          successMessage: "Test print generated (${res.data!.byteCount} bytes).",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isPrinting: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to generate test print.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isPrinting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<CashDrawerCommandModel?> openCashDrawer() async {
    state = state.copyWith(isPrinting: true, errorMessage: null);
    try {
      final res = await _repository.openCashDrawer();
      if (res.success && res.data != null) {
        state = state.copyWith(
          isPrinting: false,
          lastDrawerCommand: res.data,
          successMessage: "Cash drawer kick pulse generated (${res.data!.hexString}).",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isPrinting: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to trigger cash drawer.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isPrinting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<ReceiptPrintResultModel?> getInvoiceReceipt(int invoiceId, {int? printerId}) async {
    state = state.copyWith(isPrinting: true, errorMessage: null);
    try {
      final res = await _repository.getInvoiceReceipt(invoiceId, printerId: printerId);
      if (res.success && res.data != null) {
        state = state.copyWith(
          isPrinting: false,
          lastReceiptResult: res.data,
          successMessage: "Receipt for Invoice #${res.data!.invoiceNumber} generated.",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isPrinting: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to generate invoice receipt.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isPrinting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
