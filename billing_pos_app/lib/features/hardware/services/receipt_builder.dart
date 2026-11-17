import "dart:typed_data";
import "../models/discovered_printer_model.dart";
import "../models/printer_model.dart";
import "esc_pos_generator.dart";

/// Pure Dart Receipt & Token Composer.
/// Mirrors ReceiptBuilder.java and EscPosUtils.java from the sample printer specification.
class ReceiptBuilder {
  /// Trims text to specified maximum length.
  static String trimText(String text, int maxLength) {
    if (text.isEmpty) return "";
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  /// Builds a complete ESC/POS thermal receipt matching ReceiptBuilder.java.
  static Uint8List buildReceipt({
    required PrinterConfigurationModel config,
    required String shopName,
    required String receiptBodyText,
    String? upiId,
    double? totalAmount,
    bool printFooter = true,
    String? footerCustomText,
  }) {
    final gen = EscPosGenerator.fromModel(config);

    // 1. Header & Shop Name
    gen.center();
    gen.textLine(shopName, bold: true, doubleSize: true);
    if (config.headerCustomText != null && config.headerCustomText!.isNotEmpty) {
      gen.textLine(config.headerCustomText!);
    }
    gen.feed(1);
    gen.left();

    // 2. Receipt Body Text
    if (receiptBodyText.isNotEmpty) {
      final lines = receiptBodyText.split("\n");
      for (final line in lines) {
        gen.textLine(line);
      }
    }

    // 3. Dynamic NPCI UPI QR Code
    if (config.printQrCode && upiId != null && upiId.isNotEmpty && totalAmount != null && totalAmount > 0) {
      gen.feed(1);
      gen.upiPaymentQr(
        upiId: upiId,
        amount: totalAmount,
        merchantName: shopName,
      );
    }

    // 4. Footer Section
    if (printFooter) {
      gen.center();
      if (footerCustomText != null && footerCustomText.isNotEmpty) {
        gen.textLine(footerCustomText);
      } else if (config.footerCustomText != null && config.footerCustomText!.isNotEmpty) {
        gen.textLine(config.footerCustomText!);
      } else {
        gen.textLine("Thank You! Visit Again", bold: true);
      }
      gen.feed(2);
    }

    // 5. Hardware Commands: Kick Drawer & Paper Cut
    if (config.openCashDrawer) {
      gen.kickCashDrawer();
    }
    if (config.autoCutReceipt) {
      gen.cut();
    }

    return gen.toBytes();
  }

  /// Builds Kitchen Order Token (KOT) matching EscPosUtils.buildTokenDesign from sample code.
  static Uint8List buildKitchenToken({
    required List<TokenItemModel> items,
    required String orderId,
    required String tokenNumber,
    bool isEstimate = false,
    PrinterConfigurationModel? config,
    PrinterPaperSize paperSize = PrinterPaperSize.mm80,
  }) {
    return EscPosGenerator.buildTokenReceipt(
      items: items,
      orderId: orderId,
      tokenNumber: tokenNumber,
      isEstimate: isEstimate,
      config: config,
      paperSize: paperSize,
    );
  }
}
