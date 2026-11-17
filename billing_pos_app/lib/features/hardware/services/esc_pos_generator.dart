import "dart:convert";
import "dart:typed_data";
import "../models/discovered_printer_model.dart";
import "../models/printer_model.dart";

/// Pure Dart ESC/POS byte builder for thermal receipt printers (80mm & 58mm).
/// Supports cross-platform execution on Windows, Android, iOS without native driver lock-in.
class EscPosGenerator {
  // ESC/POS Command Byte Constants
  static const int esc = 0x1B;
  static const int gs = 0x1D;
  static const int fs = 0x1C;
  static const int lf = 0x0A;

  // Initialise
  static final Uint8List initialize = Uint8List.fromList([esc, 0x40]);

  // Alignment
  static final Uint8List alignLeft = Uint8List.fromList([esc, 0x61, 0x00]);
  static final Uint8List alignCenter = Uint8List.fromList([esc, 0x61, 0x01]);
  static final Uint8List alignRight = Uint8List.fromList([esc, 0x61, 0x02]);

  // Character Sizes
  static final Uint8List textNormal = Uint8List.fromList([gs, 0x21, 0x00]);
  static final Uint8List textDoubleWidth = Uint8List.fromList([gs, 0x21, 0x10]);
  static final Uint8List textDoubleHeight = Uint8List.fromList([gs, 0x21, 0x01]);
  static final Uint8List textDoubleSize = Uint8List.fromList([gs, 0x21, 0x11]);

  // Text Formats
  static final Uint8List boldOn = Uint8List.fromList([esc, 0x45, 0x01]);
  static final Uint8List boldOff = Uint8List.fromList([esc, 0x45, 0x00]);
  static final Uint8List underlineOn = Uint8List.fromList([esc, 0x2D, 0x01]);
  static final Uint8List underlineOff = Uint8List.fromList([esc, 0x2D, 0x00]);

  // Hardware Controls
  static final Uint8List paperCutFull = Uint8List.fromList([gs, 0x56, 0x41, 0x00]);
  static final Uint8List paperCutPartial = Uint8List.fromList([gs, 0x56, 0x42, 0x00]);
  static final Uint8List openCashDrawer = Uint8List.fromList([esc, 0x70, 0x00, 0x19, 0xFA]);

  final BytesBuilder _builder = BytesBuilder();
  final int columns;
  final PrinterPaperSize paperSize;

  EscPosGenerator({
    this.columns = 48,
    this.paperSize = PrinterPaperSize.mm80,
  }) {
    reset();
  }

  factory EscPosGenerator.fromModel(PrinterConfigurationModel config) {
    final effectiveCols = config.characterColumns > 0
        ? config.characterColumns
        : (config.paperSize == PrinterPaperSize.mm58 ? 32 : 48);
    return EscPosGenerator(
      columns: effectiveCols,
      paperSize: config.paperSize,
    );
  }

  EscPosGenerator reset() {
    _builder.add(initialize);
    return this;
  }

  EscPosGenerator center() {
    _builder.add(alignCenter);
    return this;
  }

  EscPosGenerator left() {
    _builder.add(alignLeft);
    return this;
  }

  EscPosGenerator right() {
    _builder.add(alignRight);
    return this;
  }

  EscPosGenerator bold(bool enable) {
    _builder.add(enable ? boldOn : boldOff);
    return this;
  }

  EscPosGenerator doubleSize(bool enable) {
    _builder.add(enable ? textDoubleSize : textNormal);
    return this;
  }

  EscPosGenerator text(String text, {bool bold = false, bool doubleSize = false}) {
    if (bold) _builder.add(boldOn);
    if (doubleSize) _builder.add(textDoubleSize);

    _builder.add(latin1.encode(text));

    if (doubleSize) _builder.add(textNormal);
    if (bold) _builder.add(boldOff);
    return this;
  }

  EscPosGenerator textLine(String text, {bool bold = false, bool doubleSize = false}) {
    this.text(text, bold: bold, doubleSize: doubleSize);
    _builder.addByte(lf);
    return this;
  }

  EscPosGenerator feed([int lines = 1]) {
    for (int i = 0; i < lines; i++) {
      _builder.addByte(lf);
    }
    return this;
  }

  EscPosGenerator divider([String char = "-"]) {
    final line = char * columns;
    textLine(line);
    return this;
  }

  EscPosGenerator doubleDivider() {
    return divider("=");
  }

  EscPosGenerator row(String leftText, String rightText) {
    final available = columns - leftText.length - rightText.length;
    if (available > 0) {
      final padded = "$leftText${' ' * available}$rightText";
      textLine(padded);
    } else {
      textLine(leftText);
      textLine(rightText.padLeft(columns));
    }
    return this;
  }

  EscPosGenerator table3Col(String col1, String col2, String col3, {List<int>? ratios}) {
    final r1 = ratios != null && ratios.length == 3 ? ratios[0] : (columns == 32 ? 14 : 22);
    final r2 = ratios != null && ratios.length == 3 ? ratios[1] : (columns == 32 ? 8 : 12);
    final r3 = columns - r1 - r2;

    final c1 = col1.padRight(r1).substring(0, r1);
    final c2 = col2.padRight(r2).substring(0, r2);
    final c3 = col3.padLeft(r3).substring(0, r3);

    textLine("$c1$c2$c3");
    return this;
  }

  EscPosGenerator table4Col(String col1, String col2, String col3, String col4) {
    final int wQty = 4;
    final int wRate = columns == 32 ? 6 : 8;
    final int wAmt = columns == 32 ? 7 : 10;
    final int wItem = columns - wQty - wRate - wAmt;

    final cItem = col1.padRight(wItem).substring(0, wItem);
    final cQty = col2.padLeft(wQty).substring(0, wQty);
    final cRate = col3.padLeft(wRate).substring(0, wRate);
    final cAmt = col4.padLeft(wAmt).substring(0, wAmt);

    textLine("$cItem$cQty$cRate$cAmt");
    return this;
  }

  /// Generates a standard Model 2 ESC/POS QR Code byte command sequence.
  EscPosGenerator qrCode(String data, {int size = 5}) {
    final dataBytes = utf8.encode(data);
    final dataLength = dataBytes.length;

    // 1. QR Code Model 2: 1D 28 6B 04 00 31 41 32 00
    _builder.add(Uint8List.fromList([gs, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]));

    // 2. QR Code Module Size (1-8, default 5): 1D 28 6B 03 00 31 43 <size>
    final safeSize = size.clamp(1, 8);
    _builder.add(Uint8List.fromList([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, safeSize]));

    // 3. Error Correction Level M: 1D 28 6B 03 00 31 45 31
    _builder.add(Uint8List.fromList([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]));

    // 4. Store Data: 1D 28 6B pL pH 31 50 30 <data>
    final pL = (dataLength + 3) % 256;
    final pH = (dataLength + 3) ~/ 256;
    _builder.add(Uint8List.fromList([gs, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]));
    _builder.add(dataBytes);

    // 5. Print QR Code: 1D 28 6B 03 00 31 51 30
    _builder.add(Uint8List.fromList([gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]));
    feed(1);
    return this;
  }

  /// Appends dynamic NPCI UPI Payment QR Code.
  EscPosGenerator upiPaymentQr({
    required String upiId,
    required double amount,
    String merchantName = "Merchant",
  }) {
    final upiUrl = "upi://pay?pa=$upiId&pn=$merchantName&am=${amount.toStringAsFixed(2)}&cu=INR";
    center();
    textLine("Scan To Pay (UPI):", bold: true);
    qrCode(upiUrl, size: 5);
    textLine("Amount: Rs. ${amount.toStringAsFixed(2)}", bold: true);
    left();
    return this;
  }

  EscPosGenerator kickCashDrawer() {
    _builder.add(openCashDrawer);
    return this;
  }

  EscPosGenerator cut({bool full = false}) {
    feed(3);
    _builder.add(full ? paperCutFull : paperCutPartial);
    return this;
  }

  Uint8List toBytes() {
    return _builder.toBytes();
  }

  String toBase64() {
    return base64Encode(toBytes());
  }

  /// Builds a standard test print ESC/POS receipt
  static Uint8List buildTestReceipt(PrinterConfigurationModel config) {
    final gen = EscPosGenerator.fromModel(config);
    gen.center();
    gen.textLine("=== TEST PRINT ===", bold: true, doubleSize: true);
    gen.textLine("PulsePOS / LitePOS Billing System");
    gen.textLine("Date: ${DateTime.now().toLocal().toString().split('.')[0]}");
    gen.left();
    gen.divider();
    gen.row("Printer Name:", config.printerName);
    gen.row("Connection:", config.connectionType.name.toUpperCase());
    if (config.ipAddress != null && config.ipAddress!.isNotEmpty) {
      gen.row("IP Address:", "${config.ipAddress}:${config.port}");
    }
    if (config.usbDeviceName != null && config.usbDeviceName!.isNotEmpty) {
      gen.row("USB Device:", config.usbDeviceName!);
    }
    if (config.bluetoothMacAddress != null && config.bluetoothMacAddress!.isNotEmpty) {
      gen.row("Bluetooth MAC:", config.bluetoothMacAddress!);
    }
    gen.row("Paper Size:", config.paperSize == PrinterPaperSize.mm58 ? "58mm (32 Col)" : "80mm (48 Col)");
    gen.row("Auto-Cut:", config.autoCutReceipt ? "Enabled" : "Disabled");
    gen.row("Cash Drawer:", config.openCashDrawer ? "Enabled" : "Disabled");
    gen.divider();
    gen.center();
    gen.textLine("Thermal Printer Working Properly!");
    gen.textLine("Thank You!");
    gen.feed(2);

    if (config.openCashDrawer) {
      gen.kickCashDrawer();
    }
    if (config.autoCutReceipt) {
      gen.cut();
    }
    return gen.toBytes();
  }

  /// Builds a Kitchen Order Token (KOT) / Order Token matching the sample printer specification.
  static Uint8List buildTokenReceipt({
    required List<TokenItemModel> items,
    required String orderId,
    required String tokenNumber,
    String? title,
    bool isEstimate = false,
    PrinterConfigurationModel? config,
    PrinterPaperSize paperSize = PrinterPaperSize.mm80,
  }) {
    final effectivePaperSize = config?.paperSize ?? paperSize;
    final gen = EscPosGenerator(
      columns: effectivePaperSize == PrinterPaperSize.mm58 ? 32 : 48,
      paperSize: effectivePaperSize,
    );

    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    gen.center();
    final heading = isEstimate ? "TOKEN (Estimate)" : (title ?? "KITCHEN ORDER TOKEN");
    gen.textLine(heading, bold: true, doubleSize: true);
    gen.feed(1);
    gen.left();

    gen.row("Bill No: $orderId", "$dateStr $timeStr");
    gen.divider("-");

    if (effectivePaperSize == PrinterPaperSize.mm58) {
      gen.table3Col("Item", "Qty", "Price");
      gen.divider("-");
      for (final item in items) {
        final name = item.itemName.length > 14 ? item.itemName.substring(0, 14) : item.itemName;
        gen.table3Col(name, item.quantity.toStringAsFixed(0), item.amount.toStringAsFixed(0));
      }
    } else {
      gen.table4Col("S.No Item", "Qty", "Rate", "Price");
      gen.divider("-");
      for (final item in items) {
        final label = "${item.slNo}. ${item.itemName}";
        gen.table4Col(
          label,
          item.quantity.toStringAsFixed(0),
          item.rate.toStringAsFixed(0),
          item.amount.toStringAsFixed(0),
        );
      }
    }

    gen.divider("=");
    gen.center();
    gen.textLine("YOUR ORDER NO: $tokenNumber", bold: true, doubleSize: true);
    gen.feed(2);

    if (config?.autoCutReceipt ?? true) {
      gen.cut(full: false);
    }
    return gen.toBytes();
  }

  /// Builds a customer retail invoice thermal receipt.
  static Uint8List buildInvoiceReceipt({
    required PrinterConfigurationModel config,
    required String shopName,
    required String invoiceNumber,
    required String cashierName,
    required String customerName,
    required String customerMobile,
    required List<Map<String, dynamic>> items,
    required double subTotal,
    required double discountAmount,
    required double taxAmount,
    required double grandTotal,
    required String paymentMode,
    String? upiId,
    String? footerNote,
  }) {
    final gen = EscPosGenerator.fromModel(config);

    // Header
    gen.center();
    gen.textLine(shopName, bold: true, doubleSize: true);
    if (config.headerCustomText != null && config.headerCustomText!.isNotEmpty) {
      gen.textLine(config.headerCustomText!);
    }
    gen.feed(1);
    gen.left();

    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    gen.row("Invoice #: $invoiceNumber", dateStr);
    gen.row("Cashier: $cashierName", "Mode: $paymentMode");
    if (customerMobile.isNotEmpty) {
      gen.row("Customer: $customerName", customerMobile);
    }
    gen.divider("-");

    // Items Table
    if (config.paperSize == PrinterPaperSize.mm58) {
      gen.table3Col("Item", "Qty", "Amount");
      gen.divider("-");
      for (final it in items) {
        final name = (it["productName"] as String? ?? "Item");
        final qty = (it["quantity"] as num?)?.toInt() ?? 1;
        final total = (it["lineTotal"] as num?)?.toDouble() ?? 0.0;
        final truncatedName = name.length > 14 ? name.substring(0, 14) : name;
        gen.table3Col(truncatedName, qty.toString(), total.toStringAsFixed(2));
      }
    } else {
      gen.table4Col("Item", "Qty", "Rate", "Amount");
      gen.divider("-");
      for (final it in items) {
        final name = (it["productName"] as String? ?? "Item");
        final qty = (it["quantity"] as num?)?.toInt() ?? 1;
        final rate = (it["unitPrice"] as num?)?.toDouble() ?? 0.0;
        final total = (it["lineTotal"] as num?)?.toDouble() ?? 0.0;
        gen.table4Col(name, qty.toString(), rate.toStringAsFixed(2), total.toStringAsFixed(2));
      }
    }

    gen.divider("-");
    gen.row("Sub Total:", "Rs. ${subTotal.toStringAsFixed(2)}");
    if (discountAmount > 0) {
      gen.row("Discount:", "-Rs. ${discountAmount.toStringAsFixed(2)}");
    }
    if (taxAmount > 0) {
      gen.row("GST Tax:", "Rs. ${taxAmount.toStringAsFixed(2)}");
    }
    gen.divider("=");
    gen.row("GRAND TOTAL:", "Rs. ${grandTotal.toStringAsFixed(2)}");
    gen.divider("=");

    // Dynamic UPI QR Code
    if (config.printQrCode && upiId != null && upiId.isNotEmpty && grandTotal > 0) {
      gen.feed(1);
      gen.upiPaymentQr(upiId: upiId, amount: grandTotal, merchantName: shopName);
    }

    // Footer
    gen.center();
    if (footerNote != null && footerNote.isNotEmpty) {
      gen.textLine(footerNote);
    } else if (config.footerCustomText != null && config.footerCustomText!.isNotEmpty) {
      gen.textLine(config.footerCustomText!);
    } else {
      gen.textLine("Thank You! Visit Again", bold: true);
    }
    gen.feed(2);

    if (config.openCashDrawer) {
      gen.kickCashDrawer();
    }
    if (config.autoCutReceipt) {
      gen.cut();
    }

    return gen.toBytes();
  }
}
