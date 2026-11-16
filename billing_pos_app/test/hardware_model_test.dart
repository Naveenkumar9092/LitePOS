import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";

void main() {
  group("Hardware & Thermal Printer Models Tests", () {
    test("PrinterConfigurationModel serializes to and from JSON correctly", () {
      final json = {
        "id": 1,
        "printerName": "Front Desk Thermal",
        "connectionType": 1, // Network
        "ipAddress": "192.168.1.50",
        "port": 9100,
        "usbDeviceName": null,
        "bluetoothMacAddress": null,
        "paperSize": 1, // 80mm
        "characterColumns": 48,
        "autoCutReceipt": true,
        "openCashDrawer": true,
        "printLogo": false,
        "printQrCode": true,
        "printCopies": 1,
        "headerCustomText": "Welcome to Our Cafe",
        "footerCustomText": "Thank you, Visit Again!",
        "isDefault": true,
        "isActive": true,
      };

      final model = PrinterConfigurationModel.fromJson(json);

      expect(model.id, 1);
      expect(model.printerName, "Front Desk Thermal");
      expect(model.connectionType, PrinterConnectionType.network);
      expect(model.ipAddress, "192.168.1.50");
      expect(model.port, 9100);
      expect(model.paperSize, PrinterPaperSize.mm80);
      expect(model.characterColumns, 48);
      expect(model.autoCutReceipt, true);
      expect(model.openCashDrawer, true);
      expect(model.headerCustomText, "Welcome to Our Cafe");
      expect(model.isDefault, true);

      final outJson = model.toJson();
      expect(outJson["id"], 1);
      expect(outJson["printerName"], "Front Desk Thermal");
      expect(outJson["connectionType"], 1);
      expect(outJson["paperSize"], 1);
    });

    test("PrinterConfigurationModel handles USB and 58mm enums", () {
      final json = {
        "id": 2,
        "printerName": "Dessert Bar USB",
        "connectionType": 2, // USB
        "usbDeviceName": "POS-58-USB",
        "paperSize": 2, // 58mm
        "characterColumns": 32,
        "autoCutReceipt": false,
        "openCashDrawer": false,
        "printCopies": 2,
        "isDefault": false,
        "isActive": true,
      };

      final model = PrinterConfigurationModel.fromJson(json);
      expect(model.connectionType, PrinterConnectionType.usb);
      expect(model.paperSize, PrinterPaperSize.mm58);
      expect(model.characterColumns, 32);
      expect(model.usbDeviceName, "POS-58-USB");
      expect(model.autoCutReceipt, false);

      final outJson = model.toJson();
      expect(outJson["connectionType"], 2);
      expect(outJson["paperSize"], 2);
    });

    test("PrinterConfigurationModel handles Bluetooth connection", () {
      final json = {
        "id": 3,
        "printerName": "Mobile Bluetooth 58mm",
        "connectionType": 3, // Bluetooth
        "bluetoothMacAddress": "00:11:22:33:44:55",
        "paperSize": 2,
        "characterColumns": 32,
        "autoCutReceipt": false,
        "openCashDrawer": false,
        "isDefault": false,
      };

      final model = PrinterConfigurationModel.fromJson(json);
      expect(model.connectionType, PrinterConnectionType.bluetooth);
      expect(model.bluetoothMacAddress, "00:11:22:33:44:55");

      final outJson = model.toJson();
      expect(outJson["connectionType"], 3);
    });

    test("PrinterConfigurationModel copyWith creates modified instance", () {
      const original = PrinterConfigurationModel(
        id: 1,
        printerName: "Main Printer",
        connectionType: PrinterConnectionType.network,
        port: 9100,
        paperSize: PrinterPaperSize.mm80,
      );

      final updated = original.copyWith(
        printerName: "Renamed Printer",
        port: 9200,
        isDefault: true,
      );

      expect(updated.id, 1);
      expect(updated.printerName, "Renamed Printer");
      expect(updated.port, 9200);
      expect(updated.isDefault, true);
      expect(original.printerName, "Main Printer");
    });

    test("TestPrintResultModel deserializes successfully", () {
      final json = {
        "printerName": "Main Thermal Printer",
        "paperSize": 1,
        "base64EscPosBytes": "G0BANzgyMTE=",
        "byteCount": 184,
        "plainTextPreview": "=======================\n   TEST RECEIPT\n=======================",
        "generatedAtUtc": "2026-11-14T09:00:00Z",
      };

      final model = TestPrintResultModel.fromJson(json);
      expect(model.printerName, "Main Thermal Printer");
      expect(model.paperSize, PrinterPaperSize.mm80);
      expect(model.byteCount, 184);
      expect(model.base64EscPosBytes, "G0BANzgyMTE=");
      expect(model.plainTextPreview.contains("TEST RECEIPT"), true);
    });

    test("ReceiptPrintResultModel deserializes invoice receipt output", () {
      final json = {
        "invoiceId": 105,
        "invoiceNumber": "INV-2026-000105",
        "printerName": "Billing Counter 80mm",
        "paperSize": 1,
        "base64EscPosBytes": "G0BANzgyMTE=",
        "byteCount": 612,
        "plainTextPreview": "CAFE CENTRAL\nINV-2026-000105\nTotal: 450.00",
        "generatedAtUtc": "2026-11-14T09:05:00Z",
      };

      final model = ReceiptPrintResultModel.fromJson(json);
      expect(model.invoiceId, 105);
      expect(model.invoiceNumber, "INV-2026-000105");
      expect(model.byteCount, 612);
      expect(model.paperSize, PrinterPaperSize.mm80);
      expect(model.plainTextPreview.contains("INV-2026-000105"), true);
    });

    test("CashDrawerCommandModel deserializes kick pulse data", () {
      final json = {
        "commandName": "Open Cash Drawer (Standard ESC/POS)",
        "base64EscPosBytes": "G3AAHier",
        "hexString": "1B 70 00 19 FA",
      };

      final model = CashDrawerCommandModel.fromJson(json);
      expect(model.commandName, "Open Cash Drawer (Standard ESC/POS)");
      expect(model.hexString, "1B 70 00 19 FA");
      expect(model.base64EscPosBytes, "G3AAHier");
    });
  });
}

