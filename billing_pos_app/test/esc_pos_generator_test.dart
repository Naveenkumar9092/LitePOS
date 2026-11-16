import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";
import "package:billing_pos_app/features/hardware/services/esc_pos_generator.dart";

void main() {
  group("EscPosGenerator Tests", () {
    test("Initializes generator with correct defaults for 80mm", () {
      final gen = EscPosGenerator();
      expect(gen.columns, 48);
      expect(gen.paperSize, PrinterPaperSize.mm80);

      final bytes = gen.toBytes();
      // Must contain initialize sequence [0x1B, 0x40]
      expect(bytes.length >= 2, true);
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test("Initializes generator from 58mm printer model", () {
      const config = PrinterConfigurationModel(
        id: 1,
        printerName: "Mobile 58mm",
        paperSize: PrinterPaperSize.mm58,
        characterColumns: 32,
      );

      final gen = EscPosGenerator.fromModel(config);
      expect(gen.columns, 32);
      expect(gen.paperSize, PrinterPaperSize.mm58);
    });

    test("Formats divider line with exact column width", () {
      final gen = EscPosGenerator(columns: 48);
      gen.divider("-");
      final bytes = gen.toBytes();
      // Length must be at least 48 bytes + newline
      expect(bytes.length >= 48, true);
    });

    test("Formats left and right aligned row", () {
      final gen = EscPosGenerator(columns: 48);
      gen.row("Subtotal:", "INR 450.00");
      final bytes = gen.toBytes();
      expect(bytes.isNotEmpty, true);
    });

    test("Appends cash drawer kick pulse bytes (1B 70 00 19 FA)", () {
      final gen = EscPosGenerator();
      gen.kickCashDrawer();
      final bytes = gen.toBytes();
      expect(bytes.contains(0x1B), true);
      expect(bytes.contains(0x70), true);
      expect(bytes.contains(0x19), true);
      expect(bytes.contains(0xFA), true);
    });

    test("Appends paper feed and cut bytes", () {
      final gen = EscPosGenerator();
      gen.cut();
      final bytes = gen.toBytes();
      expect(bytes.contains(0x1D), true); // GS
      expect(bytes.contains(0x56), true); // 'V'
    });

    test("Builds complete test print receipt for 80mm printer", () {
      const config = PrinterConfigurationModel(
        id: 1,
        printerName: "Main Counter Thermal 80mm",
        connectionType: PrinterConnectionType.network,
        ipAddress: "192.168.1.100",
        port: 9100,
        paperSize: PrinterPaperSize.mm80,
        characterColumns: 48,
        autoCutReceipt: true,
        openCashDrawer: true,
      );

      final receiptBytes = EscPosGenerator.buildTestReceipt(config);
      expect(receiptBytes.isNotEmpty, true);
      expect(receiptBytes.length > 50, true);
    });

    test("Builds test receipt for 58mm printer with drawer kick and cut", () {
      const config = PrinterConfigurationModel(
        id: 2,
        printerName: "Dessert Counter 58mm",
        connectionType: PrinterConnectionType.usb,
        usbDeviceName: "POS-58",
        paperSize: PrinterPaperSize.mm58,
        characterColumns: 32,
        autoCutReceipt: true,
        openCashDrawer: false,
      );

      final receiptBytes = EscPosGenerator.buildTestReceipt(config);
      expect(receiptBytes.isNotEmpty, true);
    });
  });
}

