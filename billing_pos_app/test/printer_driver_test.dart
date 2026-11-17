import "dart:convert";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/hardware/models/discovered_printer_model.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";
import "package:billing_pos_app/features/hardware/services/esc_pos_generator.dart";

void main() {
  group("Printer Driver & KOT Token Tests", () {
    test("DiscoveredPrinterModel parses Bluetooth device correctly", () {
      final map = {
        "name": "PMN-1.5-EC2518",
        "address": "66:32:89:43:95:90",
        "type": "bluetooth",
        "connected": true,
      };

      final model = DiscoveredPrinterModel.fromMap(map, PrinterConnectionType.bluetooth);
      expect(model.name, "PMN-1.5-EC2518");
      expect(model.address, "66:32:89:43:95:90");
      expect(model.connectionType, PrinterConnectionType.bluetooth);
      expect(model.isOnline, true);
    });

    test("DiscoveredPrinterModel parses USB device correctly", () {
      final map = {
        "name": "POS-80 USB Thermal",
        "address": "1002",
        "type": "usb",
        "vendorId": 1155,
        "productId": 22339,
      };

      final model = DiscoveredPrinterModel.fromMap(map, PrinterConnectionType.usb);
      expect(model.name, "POS-80 USB Thermal");
      expect(model.address, "1002");
      expect(model.connectionType, PrinterConnectionType.usb);
      expect(model.extraInfo, contains("VID:1155 PID:22339"));
    });

    test("TokenItemModel serializes and deserializes properly", () {
      const token = TokenItemModel(
        slNo: 1,
        itemName: "Cold Coffee",
        quantity: 2.0,
        rate: 60.0,
        amount: 120.0,
      );

      final json = token.toJson();
      expect(json["foodName"], "Cold Coffee");
      expect(json["qty"], 2.0);
      expect(json["rate"], 60.0);
      expect(json["price"], 120.0);

      final revived = TokenItemModel.fromJson(json);
      expect(revived.itemName, "Cold Coffee");
      expect(revived.quantity, 2.0);
      expect(revived.amount, 120.0);
    });

    test("EscPosGenerator generates standard Model 2 QR Code bytes", () {
      final gen = EscPosGenerator();
      gen.qrCode("upi://pay?pa=test@upi&pn=Cafe&am=100.00&cu=INR", size: 5);

      final bytes = gen.toBytes();
      expect(bytes.isNotEmpty, true);

      // Model 2 header: 1D 28 6B 04 00 31 41 32 00
      expect(bytes.contains(0x1D), true);
      expect(bytes.contains(0x28), true);
      expect(bytes.contains(0x6B), true);
    });

    test("EscPosGenerator builds Kitchen Order Token (KOT) receipt with correct layout", () {
      final items = [
        const TokenItemModel(slNo: 1, itemName: "Masala Dosa", quantity: 2, rate: 50, amount: 100),
        const TokenItemModel(slNo: 2, itemName: "Filter Coffee", quantity: 1, rate: 25, amount: 25),
      ];

      const config = PrinterConfigurationModel(
        id: 1,
        printerName: "Kitchen Printer",
        connectionType: PrinterConnectionType.network,
        paperSize: PrinterPaperSize.mm80,
        autoCutReceipt: true,
      );

      final bytes = EscPosGenerator.buildTokenReceipt(
        items: items,
        orderId: "INV-2026-0042",
        tokenNumber: "42",
        config: config,
      );

      expect(bytes.isNotEmpty, true);
      final textContent = latin1.decode(bytes, allowInvalid: true);
      expect(textContent, contains("KITCHEN ORDER TOKEN"));
      expect(textContent, contains("Bill No: INV-2026-0042"));
      expect(textContent, contains("Masala Dosa"));
      expect(textContent, contains("Filter Coffee"));
      expect(textContent, contains("YOUR ORDER NO: 42"));
    });
  });
}
