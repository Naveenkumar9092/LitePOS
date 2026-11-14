import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";
import "package:billing_pos_app/features/hardware/presentation/hardware_state.dart";

void main() {
  group("HardwareState Tests", () {
    const testPrinter = PrinterConfigurationModel(
      id: 1,
      printerName: "Counter 80mm",
      connectionType: PrinterConnectionType.network,
      ipAddress: "192.168.1.100",
      port: 9100,
      paperSize: PrinterPaperSize.mm80,
      isDefault: true,
    );

    test("Initial HardwareState defaults are correct", () {
      const state = HardwareState();
      expect(state.isLoading, false);
      expect(state.isPrinting, false);
      expect(state.printers, isEmpty);
      expect(state.defaultPrinter, isNull);
      expect(state.lastTestPrint, isNull);
      expect(state.lastDrawerCommand, isNull);
      expect(state.lastReceiptResult, isNull);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test("HardwareState copyWith updates fields properly", () {
      const state = HardwareState();
      final updated = state.copyWith(
        isLoading: true,
        printers: [testPrinter],
        defaultPrinter: testPrinter,
        successMessage: "Printer updated successfully",
      );

      expect(updated.isLoading, true);
      expect(updated.printers.length, 1);
      expect(updated.defaultPrinter?.printerName, "Counter 80mm");
      expect(updated.successMessage, "Printer updated successfully");
      expect(updated.errorMessage, isNull);
    });

    test("HardwareState copyWith can clear defaultPrinter", () {
      final state = const HardwareState().copyWith(
        defaultPrinter: testPrinter,
      );
      expect(state.defaultPrinter, isNotNull);

      final cleared = state.copyWith(clearDefaultPrinter: true);
      expect(cleared.defaultPrinter, isNull);
    });
  });
}

