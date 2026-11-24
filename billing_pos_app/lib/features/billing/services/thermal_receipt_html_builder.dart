import "package:intl/intl.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/company/models/company_model.dart";

/// Pure Dart ISO/IEC 15417 Code 128 (Subset B) vector barcode generator.
/// Generates crisp, scanner-readable SVG barcodes without external dependencies.
class Code128BarcodeGenerator {
  static const List<String> _patterns = [
    "11011001100", "11001101100", "11001100110", "10010011000", "10010001100", // 0-4
    "10001001100", "10011001000", "10011000100", "10001100100", "11001001000", // 5-9
    "11001000100", "11000100100", "10110011100", "10011011100", "10011001110", // 10-14
    "10111001100", "10011101100", "10011100110", "11001110010", "11001011100", // 15-19
    "11001001110", "11011100100", "11001110100", "11101101110", "11101001100", // 20-24
    "11100101100", "11100100110", "11101100100", "11100110100", "11100110010", // 25-29
    "11011011000", "11011000110", "11000110110", "10100011000", "10001011000", // 30-34
    "10001000110", "10110001000", "10001101000", "10001100010", "11010001000", // 35-39
    "11000101000", "11000100010", "10110111000", "10110001110", "10001101110", // 40-44
    "10111011000", "10111000110", "10001110110", "11101110110", "11010001110", // 45-49
    "11000101110", "11011101000", "11011100010", "11011101110", "11101011000", // 50-54
    "11101000110", "11100010110", "11101101000", "11101100010", "11100011010", // 55-59
    "11101111010", "11001000010", "11110001010", "10100110000", "10100001100", // 60-64
    "10010110000", "10010000110", "10000101100", "10000100110", "10110010000", // 65-69
    "10110000100", "10011010000", "10011000010", "10000110100", "10000110010", // 70-74
    "11000010010", "11001010000", "11110111010", "11000010100", "10001111010", // 75-79
    "10100111100", "10010111100", "10010011110", "10111100100", "10011110100", // 80-84
    "10011110010", "11110100100", "11110010100", "11110010010", "11011011110", // 85-89
    "11011110110", "11110110110", "10101111000", "10100011110", "10001011110", // 90-94
    "10111101000", "10111100010", "11110101000", "11110100010", "10111011110", // 95-99
    "10111101110", "11101011110", "11110101110", // 100-102
    "11010000100", // 103 (Start A)
    "11010010000", // 104 (Start B)
    "11010011100", // 105 (Start C)
    "1100011101011", // 106 (Stop)
  ];

  /// Generates a valid SVG representation of a Code128-B barcode.
  static String toSvg(
    String text, {
    double height = 38.0,
    double moduleWidth = 1.35,
  }) {
    if (text.isEmpty) return "";

    final values = <int>[];
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 32 && code <= 126) {
        values.add(code - 32);
      } else {
        values.add(0); // Fallback space
      }
    }

    // Start Code B is index 104
    int checksum = 104;
    for (int i = 0; i < values.length; i++) {
      checksum += values[i] * (i + 1);
    }
    checksum = checksum % 103;

    final buffer = StringBuffer();
    // Start B
    buffer.write(_patterns[104]);
    // Data symbols
    for (final v in values) {
      buffer.write(_patterns[v]);
    }
    // Checksum
    buffer.write(_patterns[checksum]);
    // Stop symbol
    buffer.write(_patterns[106]);

    final bitString = buffer.toString();
    final totalWidth = bitString.length * moduleWidth;

    final svgBuffer = StringBuffer();
    svgBuffer.write('<svg xmlns="http://www.w3.org/2000/svg" width="$totalWidth" height="$height" viewBox="0 0 $totalWidth $height">');
    svgBuffer.write('<rect width="$totalWidth" height="$height" fill="#ffffff"/>');

    double currentX = 0;
    for (int i = 0; i < bitString.length; i++) {
      if (bitString[i] == "1") {
        svgBuffer.write('<rect x="$currentX" y="0" width="$moduleWidth" height="$height" fill="#000000"/>');
      }
      currentX += moduleWidth;
    }

    svgBuffer.write("</svg>");
    return svgBuffer.toString();
  }
}

/// Reusable HTML + CSS generator for ListPos 3-inch (80mm) Thermal Receipts.
/// Adheres strictly to the 80mm thermal printer standard (~72mm printable width)
/// and all retail billing specifications.
class ThermalReceiptHtmlBuilder {
  static String escapeHtml(String text) {
    return text
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
  }

  /// Builds a complete, standalone 80mm thermal receipt HTML document.
  static String build80mmReceiptHtml({
    required BillingInvoiceModel invoice,
    ShopModel? shop,
    CompanyProfileModel? company,
    String? upiId,
    bool isIgst = false,
    String brandName = "ListPos",
  }) {
    // 1. Shop information resolution
    final effectiveShopName = (shop?.shopName.isNotEmpty ?? false)
        ? shop!.shopName
        : (invoice.shopName.isNotEmpty ? invoice.shopName : "ListPos Retail Store");

    final effectiveAddress1 = shop?.addressLine1 ?? "";
    final effectiveAddress2 = shop?.addressLine2 ?? "";
    final effectiveCity = shop?.city ?? "";
    final effectiveState = shop?.state ?? "";
    final effectivePincode = shop?.pincode ?? "";

    final addressParts = <String>[];
    if (effectiveAddress1.isNotEmpty) addressParts.add(effectiveAddress1);
    if (effectiveAddress2.isNotEmpty) addressParts.add(effectiveAddress2);
    final locationLine = [
      if (effectiveCity.isNotEmpty) effectiveCity,
      if (effectiveState.isNotEmpty) effectiveState,
      if (effectivePincode.isNotEmpty) effectivePincode,
    ].join(" ");
    if (locationLine.isNotEmpty) addressParts.add(locationLine);

    final effectiveContact = (shop?.contactNumber.isNotEmpty ?? false)
        ? shop!.contactNumber
        : ((company?.mobileNumber.isNotEmpty ?? false) ? company!.mobileNumber : "");

    final effectiveGstin = (company?.gstin?.isNotEmpty ?? false) ? company!.gstin! : "";

    // 2. Combined Date & Time (Strict requirement: dd-MM-yyyy hh:mm a)
    final invoiceDateTime = DateFormat("dd-MM-yyyy hh:mm a").format(invoice.invoiceDateUtc.toLocal());

    // 3. Customer Information (Strict conditional display)
    final rawCustomerName = invoice.customerName?.trim() ?? "";
    final rawCustomerMobile = invoice.customerMobile?.trim() ?? "";
    final isCustomerAvailable = rawCustomerName.isNotEmpty &&
        rawCustomerName.toLowerCase() != "walk-in" &&
        rawCustomerName.toLowerCase() != "walk-in customer" &&
        rawCustomerName.toLowerCase() != "walk-in guest";

    // 4. Tax Breakdown
    final bool hasTax = invoice.taxAmount > 0;
    final double cgstAmount = hasTax && !isIgst ? invoice.taxAmount / 2 : 0.0;
    final double sgstAmount = hasTax && !isIgst ? invoice.taxAmount / 2 : 0.0;
    final double igstAmount = hasTax && isIgst ? invoice.taxAmount : 0.0;

    // 5. Payment details resolution
    final payments = invoice.payments;
    final isSplitPayment = payments.length > 1;
    final defaultPaymentMode = payments.isNotEmpty ? payments.first.paymentModeName : "Cash";

    // 6. Barcode generation
    final barcodeSvg = Code128BarcodeGenerator.toSvg(invoice.invoiceNumber);

    // 7. UPI QR Code resolution (Display only when configured and available)
    final effectiveUpi = upiId ?? (effectiveGstin.isNotEmpty ? null : null);
    final bool showUpiQr = effectiveUpi != null && effectiveUpi.isNotEmpty && invoice.grandTotal > 0;

    // 8. Custom Header / Footer messages
    final customFooter = shop?.invoiceFooter?.trim();
    final website = company?.website?.trim();

    final buffer = StringBuffer();
    buffer.write("""
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Receipt #${escapeHtml(invoice.invoiceNumber)}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @page {
      size: 80mm auto;
      margin: 0;
    }
    @media print {
      body {
        margin: 0 !important;
        padding: 0 !important;
        background: #ffffff !important;
      }
      .no-print {
        display: none !important;
      }
      .receipt-container {
        border: none !important;
        box-shadow: none !important;
        width: 72mm !important;
        max-width: 72mm !important;
        margin: 0 auto !important;
        padding: 2mm 0 !important;
      }
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: Arial, "Helvetica Neue", Helvetica, sans-serif;
      font-size: 11px;
      line-height: 1.32;
      color: #000000;
      background-color: #e9ecef;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    .receipt-container {
      width: 76mm;
      max-width: 80mm;
      margin: 12px auto;
      background: #ffffff;
      padding: 5mm 3.5mm;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.12);
      border-radius: 4px;
    }
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .text-left { text-align: left; }
    .font-bold { font-weight: bold; }
    .uppercase { text-transform: uppercase; }

    /* ListPos Brand Header */
    .brand-header {
      text-align: center;
      margin-bottom: 3px;
    }
    .brand-name {
      font-size: 13px;
      font-weight: 900;
      letter-spacing: 1.8px;
      color: #111111;
    }
    .brand-tag {
      font-size: 8.5px;
      font-weight: 600;
      letter-spacing: 0.8px;
      color: #444444;
      margin-bottom: 4px;
    }

    /* Shop Information */
    .shop-header {
      text-align: center;
      margin-bottom: 6px;
    }
    .shop-name {
      font-size: 15px;
      font-weight: 900;
      letter-spacing: 0.4px;
      line-height: 1.25;
      margin-bottom: 2px;
      word-break: break-word;
    }
    .shop-details {
      font-size: 10px;
      color: #111111;
      line-height: 1.35;
    }
    .tax-badge {
      font-size: 11.5px;
      font-weight: 900;
      letter-spacing: 1.2px;
      text-align: center;
      padding: 3px 0;
      margin: 6px 0 4px 0;
      border-top: 1px dashed #000000;
      border-bottom: 1px dashed #000000;
    }

    /* Separators */
    .divider-dashed {
      border-top: 1px dashed #000000;
      margin: 5px 0;
    }
    .divider-solid {
      border-top: 1px solid #000000;
      margin: 5px 0;
    }
    .divider-double {
      border-top: 1.5px solid #000000;
      border-bottom: 1px solid #000000;
      height: 2px;
      margin: 5px 0;
    }

    /* Invoice Metadata */
    .meta-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 10.5px;
      margin-bottom: 4px;
    }
    .meta-table td {
      padding: 1.5px 0;
      vertical-align: top;
    }
    .meta-table .label {
      color: #222222;
      font-weight: normal;
      width: 32%;
    }
    .meta-table .val {
      font-weight: 700;
      text-align: right;
      width: 68%;
      word-break: break-word;
    }

    /* Conditional Customer Box */
    .customer-box {
      border-top: 1px dashed #666666;
      border-bottom: 1px dashed #666666;
      padding: 3px 0;
      margin: 4px 0;
      font-size: 10px;
    }
    .customer-box table {
      width: 100%;
    }
    .customer-box td {
      padding: 1px 0;
    }

    /* Product Items Table (5 Columns: #, Item, Qty, Rate, Amount) */
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 5px 0;
      font-size: 10px;
    }
    .items-table th {
      border-top: 1px dashed #000000;
      border-bottom: 1px dashed #000000;
      padding: 3.5px 1px;
      font-weight: 800;
      font-size: 9.5px;
      text-transform: uppercase;
    }
    .items-table td {
      padding: 3px 1px;
      vertical-align: top;
      word-break: break-word;
    }
    .col-sno { width: 7%; text-align: left; }
    .col-item { width: 45%; text-align: left; }
    .col-qty { width: 12%; text-align: right; }
    .col-rate { width: 17%; text-align: right; }
    .col-amt { width: 19%; text-align: right; }

    /* Summary Totals */
    .summary-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 10.5px;
      margin-top: 2px;
    }
    .summary-table td {
      padding: 1.5px 0;
    }
    .summary-table .sum-lbl {
      color: #222222;
      font-weight: normal;
      text-align: left;
    }
    .summary-table .sum-val {
      font-weight: 700;
      text-align: right;
    }

    /* Grand Total Prominent Highlight */
    .grand-total-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 5px 0;
      margin: 4px 0;
      border-top: 1.5px solid #000000;
      border-bottom: 1.5px solid #000000;
    }
    .grand-total-label {
      font-size: 13.5px;
      font-weight: 900;
      letter-spacing: 0.5px;
    }
    .grand-total-value {
      font-size: 15.5px;
      font-weight: 900;
    }

    /* Payment Info */
    .payment-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 10.5px;
      margin: 4px 0;
    }
    .payment-table td {
      padding: 1.5px 0;
    }

    /* Barcode Section */
    .barcode-section {
      text-align: center;
      margin: 8px 0 4px 0;
    }
    .barcode-svg-wrap {
      display: inline-block;
      margin: 0 auto;
    }
    .barcode-caption {
      font-family: "Courier New", Courier, monospace;
      font-size: 9.5px;
      font-weight: bold;
      letter-spacing: 2px;
      margin-top: 2px;
    }

    /* UPI QR Section */
    .qr-section {
      text-align: center;
      margin: 8px 0;
    }
    .qr-caption {
      font-size: 8.5px;
      color: #333333;
      margin-top: 2px;
    }

    /* Receipt Footer */
    .receipt-footer {
      text-align: center;
      margin-top: 8px;
      font-size: 10px;
      line-height: 1.35;
    }
    .footer-thanks {
      font-size: 11.5px;
      font-weight: 900;
      letter-spacing: 0.5px;
    }
    .footer-visit {
      font-size: 10.5px;
      font-weight: 700;
      margin-bottom: 3px;
    }
    .footer-sub {
      font-size: 9px;
      color: #333333;
      margin-top: 2px;
    }
  </style>
</head>
<body>
  <div class="receipt-container">

    <!-- 1. Header: ListPos Logo & Shop Information -->
    <div class="brand-header">
      <div class="brand-name">${escapeHtml(brandName.toUpperCase())}</div>
      <div class="brand-tag">&bull; SMART RETAIL POS &bull;</div>
    </div>

    <div class="shop-header">
      <div class="shop-name">${escapeHtml(effectiveShopName)}</div>
""");

    for (final line in addressParts) {
      buffer.write('      <div class="shop-details">${escapeHtml(line)}</div>\n');
    }

    if (effectiveContact.isNotEmpty) {
      buffer.write('      <div class="shop-details">Phone: ${escapeHtml(effectiveContact)}</div>\n');
    }

    if (effectiveGstin.isNotEmpty) {
      buffer.write('      <div class="shop-details font-bold">GSTIN: ${escapeHtml(effectiveGstin)}</div>\n');
    }

    buffer.write("""
    </div>

    <div class="tax-badge">TAX INVOICE</div>

    <!-- 2. Invoice Information (Combined Date & Time) -->
    <table class="meta-table">
      <tr>
        <td class="label">Bill No:</td>
        <td class="val">${escapeHtml(invoice.invoiceNumber)}</td>
      </tr>
      <tr>
        <td class="label">Date:</td>
        <td class="val">${escapeHtml(invoiceDateTime)}</td>
      </tr>
      <tr>
        <td class="label">Cashier:</td>
        <td class="val">${escapeHtml(invoice.cashierName.isNotEmpty ? invoice.cashierName : 'Counter')}</td>
      </tr>
""");

    if (invoice.deviceId.isNotEmpty) {
      buffer.write("""
      <tr>
        <td class="label">POS Term:</td>
        <td class="val">${escapeHtml(invoice.deviceId)}</td>
      </tr>
""");
    }

    buffer.write("    </table>\n");

    // 3. Customer Information (Strictly Conditional)
    if (isCustomerAvailable) {
      buffer.write("""
    <!-- 3. Customer Information -->
    <div class="customer-box">
      <table>
        <tr>
          <td style="width: 30%; color: #333;">Customer:</td>
          <td style="width: 70%; font-weight: bold; text-align: right;">${escapeHtml(rawCustomerName)}</td>
        </tr>
""");
      if (rawCustomerMobile.isNotEmpty) {
        buffer.write("""
        <tr>
          <td style="width: 30%; color: #333;">Mobile:</td>
          <td style="width: 70%; font-weight: bold; text-align: right;">${escapeHtml(rawCustomerMobile)}</td>
        </tr>
""");
      }
      buffer.write("""
      </table>
    </div>
""");
    }

    // 4. Product Items Table (5 Columns: #, Item, Qty, Rate, Amount)
    buffer.write("""
    <!-- 4. Product Items Table -->
    <table class="items-table">
      <thead>
        <tr>
          <th class="col-sno">#</th>
          <th class="col-item">Item</th>
          <th class="col-qty">Qty</th>
          <th class="col-rate">Rate</th>
          <th class="col-amt">Amount</th>
        </tr>
      </thead>
      <tbody>
""");

    int itemIndex = 1;
    for (final item in invoice.items) {
      final name = item.productNameSnapshot.isNotEmpty ? item.productNameSnapshot : "Item";
      final qty = item.quantity;
      final rate = item.unitPrice.toStringAsFixed(2);
      final amt = item.lineTotal.toStringAsFixed(2);

      buffer.write("""
        <tr>
          <td class="col-sno">$itemIndex</td>
          <td class="col-item">${escapeHtml(name)}</td>
          <td class="col-qty">$qty</td>
          <td class="col-rate">$rate</td>
          <td class="col-amt font-bold">$amt</td>
        </tr>
""");
      itemIndex++;
    }

    buffer.write("""
      </tbody>
    </table>

    <div class="divider-dashed"></div>

    <!-- 5. Billing Summary -->
    <table class="summary-table">
      <tr>
        <td class="sum-lbl">Subtotal:</td>
        <td class="sum-val">&#8377;${invoice.subTotal.toStringAsFixed(2)}</td>
      </tr>
""");

    if (invoice.discountAmount > 0) {
      buffer.write("""
      <tr>
        <td class="sum-lbl">Discount:</td>
        <td class="sum-val">-&#8377;${invoice.discountAmount.toStringAsFixed(2)}</td>
      </tr>
""");
    }

    buffer.write("""
      <tr>
        <td class="sum-lbl">Taxable Amount:</td>
        <td class="sum-val">&#8377;${invoice.taxableAmount.toStringAsFixed(2)}</td>
      </tr>
""");

    if (hasTax) {
      if (isIgst) {
        buffer.write("""
      <tr>
        <td class="sum-lbl">IGST:</td>
        <td class="sum-val">&#8377;${igstAmount.toStringAsFixed(2)}</td>
      </tr>
""");
      } else {
        buffer.write("""
      <tr>
        <td class="sum-lbl">CGST:</td>
        <td class="sum-val">&#8377;${cgstAmount.toStringAsFixed(2)}</td>
      </tr>
      <tr>
        <td class="sum-lbl">SGST:</td>
        <td class="sum-val">&#8377;${sgstAmount.toStringAsFixed(2)}</td>
      </tr>
""");
      }
    }

    buffer.write("""
    </table>

    <!-- Highlighted Grand Total -->
    <div class="grand-total-row">
      <div class="grand-total-label">GRAND TOTAL:</div>
      <div class="grand-total-value">&#8377;${invoice.grandTotal.toStringAsFixed(2)}</div>
    </div>

    <!-- 6. Payment Information -->
    <table class="payment-table">
""");

    if (isSplitPayment) {
      buffer.write("""
      <tr>
        <td colspan="2" class="font-bold" style="padding-bottom: 2px;">Split Settlement:</td>
      </tr>
""");
      for (final p in payments) {
        buffer.write("""
      <tr>
        <td style="color: #333; padding-left: 6px;">${escapeHtml(p.paymentModeName)}:</td>
        <td style="text-align: right; font-weight: bold;">&#8377;${p.amount.toStringAsFixed(2)}</td>
      </tr>
""");
      }
    } else {
      buffer.write("""
      <tr>
        <td style="color: #333;">Payment Mode:</td>
        <td style="text-align: right; font-weight: bold;">${escapeHtml(defaultPaymentMode)}</td>
      </tr>
""");
    }

    buffer.write("""
      <tr>
        <td style="color: #333;">Paid Amount:</td>
        <td style="text-align: right; font-weight: bold;">&#8377;${invoice.paidAmount.toStringAsFixed(2)}</td>
      </tr>
""");

    if (invoice.balanceAmount > 0) {
      buffer.write("""
      <tr>
        <td style="color: #333;">Balance Due:</td>
        <td style="text-align: right; font-weight: bold; color: #b70000;">&#8377;${invoice.balanceAmount.toStringAsFixed(2)}</td>
      </tr>
""");
    }

    buffer.write("""
    </table>
""");

    // Dynamic Barcode
    if (barcodeSvg.isNotEmpty) {
      buffer.write("""
    <!-- 7. Dynamic Barcode Reference -->
    <div class="barcode-section">
      <div class="barcode-svg-wrap">
        $barcodeSvg
      </div>
      <div class="barcode-caption">${escapeHtml(invoice.invoiceNumber)}</div>
    </div>
""");
    }

    // Dynamic UPI QR Code (Only if configured and available)
    if (showUpiQr) {
      buffer.write("""
    <!-- Dynamic UPI Payment QR -->
    <div class="qr-section">
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=upi%3A%2F%2Fpay%3Fpa%3D${Uri.encodeComponent(effectiveUpi)}%26pn%3D${Uri.encodeComponent(effectiveShopName)}%26am%3D${invoice.grandTotal.toStringAsFixed(2)}%26cu%3DINR"
           width="90" height="90" alt="UPI QR" style="display: inline-block;"/>
      <div class="qr-caption">Scan with any UPI App to Pay</div>
    </div>
""");
    }

    // 8. Footer
    buffer.write("""
    <div class="divider-dashed"></div>

    <div class="receipt-footer">
      <div class="footer-thanks">Thank You!</div>
      <div class="footer-visit">Visit Again!</div>
""");

    if (customFooter != null && customFooter.isNotEmpty) {
      buffer.write('      <div class="footer-sub">${escapeHtml(customFooter)}</div>\n');
    }

    if (website != null && website.isNotEmpty) {
      buffer.write('      <div class="footer-sub">${escapeHtml(website)}</div>\n');
    }

    buffer.write("""
      <div class="footer-sub" style="font-size: 8px; color: #777; margin-top: 4px;">Powered by ListPos</div>
    </div>

  </div>
</body>
</html>
""");

    return buffer.toString();
  }
}
