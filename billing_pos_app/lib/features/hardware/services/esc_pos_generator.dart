import "dart:convert";
import "dart:typed_data";
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
    gen.textLine("LitePOS Billing System");
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
}

