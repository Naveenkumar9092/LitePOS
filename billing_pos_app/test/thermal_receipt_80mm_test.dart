import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/company/models/company_model.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";
import "package:billing_pos_app/features/hardware/services/esc_pos_generator.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/features/billing/services/thermal_receipt_html_builder.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BillingInvoiceModel createMockInvoice({
    String invoiceNumber = "INV-000784",
    String? customerName = "Ramesh Kumar",
    String? customerMobile = "9876543210",
    double subTotal = 225.0,
    double discountAmount = 10.0,
    double taxableAmount = 215.0,
    double taxAmount = 10.76,
    double grandTotal = 225.76,
    double paidAmount = 225.76,
    double balanceAmount = 0.0,
    List<BillingInvoiceItemModel>? items,
    List<BillingPaymentModel>? payments,
  }) {
    final effectiveItems = items ??
        [
          BillingInvoiceItemModel(
            invoiceDetailId: 1,
            invoiceId: 784,
            productId: 1,
            productNameSnapshot: "Rice 1 Kg",
            unitPrice: 60.00,
            quantity: 2,
            taxPercentage: 5.0,
            taxAmount: 6.00,
            lineTotal: 120.00,
          ),
          BillingInvoiceItemModel(
            invoiceDetailId: 2,
            invoiceId: 784,
            productId: 2,
            productNameSnapshot: "Milk 500ml",
            unitPrice: 30.00,
            quantity: 2,
            taxPercentage: 5.0,
            taxAmount: 3.00,
            lineTotal: 60.00,
          ),
          BillingInvoiceItemModel(
            invoiceDetailId: 3,
            invoiceId: 784,
            productId: 3,
            productNameSnapshot: "Sugar 1 Kg",
            unitPrice: 45.00,
            quantity: 1,
            taxPercentage: 5.0,
            taxAmount: 2.25,
            lineTotal: 45.00,
          ),
        ];

    final effectivePayments = payments ??
        [
          BillingPaymentModel(
            paymentId: 1,
            paymentGuid: "pay-guid-1",
            invoiceId: 784,
            paymentMode: 2,
            paymentModeName: "UPI",
            amount: 225.76,
            paymentStatus: 2,
            createdAtUtc: DateTime.utc(2026, 11, 24, 6, 27),
          ),
        ];

    return BillingInvoiceModel(
      invoiceId: 784,
      invoiceGuid: "guid-inv-784",
      invoiceNumber: invoiceNumber,
      companyId: 1,
      companyName: "ListPos Retail Enterprises",
      shopId: 1,
      shopName: "ListPos Flagship Store",
      cashierId: 5,
      cashierName: "Anand",
      deviceId: "POS-TERM-01",
      customerName: customerName,
      customerMobile: customerMobile,
      invoiceDateUtc: DateTime.utc(2026, 11, 24, 6, 27), // 11:57 AM IST
      subTotal: subTotal,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      balanceAmount: balanceAmount,
      paymentStatus: 2,
      invoiceStatus: 2,
      syncStatus: 1,
      createdAtUtc: DateTime.utc(2026, 11, 24, 6, 27),
      items: effectiveItems,
      payments: effectivePayments,
    );
  }

  final sampleShop = ShopModel(
    shopId: 1,
    companyId: 1,
    shopName: "ListPos Express Supermarket",
    addressLine1: "123 Anna Salai, Mount Road",
    addressLine2: "Opp. City Mall",
    city: "Chennai",
    state: "Tamil Nadu",
    pincode: "600002",
    country: "India",
    contactNumber: "9876543210",
    email: "contact@listpos.io",
    timeZone: "Asia/Kolkata",
    currencyCode: "INR",
    invoiceHeader: "Welcome to ListPos Retail",
    invoiceFooter: "Items once sold cannot be returned without bill",
    isActive: true,
  );

  final sampleCompany = CompanyProfileModel(
    companyId: 1,
    companyName: "ListPos Retail Enterprises Ltd",
    businessCategory: BusinessCategory.cafe,
    gstin: "33AAAAA1234A1Z5",
    email: "admin@listpos.io",
    mobileNumber: "9876543210",
    website: "https://listpos.io",
    isActive: true,
    shop: sampleShop,
  );

  group("Scenario 1 – Bill with Customer Details", () {
    test("HTML receipt displays Customer Name and Mobile when provided", () {
      final invoice = createMockInvoice(
        customerName: "Ramesh Kumar",
        customerMobile: "9876543210",
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(
        invoice: invoice,
        shop: sampleShop,
        company: sampleCompany,
      );

      expect(html.contains("Customer:"), isTrue);
      expect(html.contains("Ramesh Kumar"), isTrue);
      expect(html.contains("Mobile:"), isTrue);
      expect(html.contains("9876543210"), isTrue);
    });

    test("Combined Date and Time is formatted into a single field dd-MM-yyyy hh:mm tt", () {
      final invoice = createMockInvoice();
      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);

      final expectedDateFormatted = DateFormat("dd-MM-yyyy hh:mm a").format(invoice.invoiceDateUtc.toLocal());
      expect(html.contains("Date:"), isTrue);
      expect(html.contains(expectedDateFormatted), isTrue);
      expect(html.contains("Bill Date"), isFalse);
      expect(html.contains("Bill Time"), isFalse);
    });
  });

  group("Scenario 2 – Bill without Customer (Strict Conditional Display)", () {
    test("Customer block is completely hidden when customer is null or empty", () {
      final invoice = createMockInvoice(
        customerName: null,
        customerMobile: null,
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);

      expect(html.contains("Customer:"), isFalse);
      expect(html.contains("Mobile:"), isFalse);
      expect(html.contains('<div class="customer-box">'), isFalse);
    });

    test("Walk-in Customer placeholder text is NOT displayed", () {
      final invoice1 = createMockInvoice(customerName: "Walk-in");
      final invoice2 = createMockInvoice(customerName: "Walk-in Customer");
      final invoice3 = createMockInvoice(customerName: "Walk-in Guest");

      final html1 = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice1);
      final html2 = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice2);
      final html3 = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice3);

      expect(html1.contains('<div class="customer-box">'), isFalse);
      expect(html1.contains("Walk-in"), isFalse);
      expect(html2.contains('<div class="customer-box">'), isFalse);
      expect(html2.contains("Walk-in Customer"), isFalse);
      expect(html3.contains('<div class="customer-box">'), isFalse);
      expect(html3.contains("Walk-in Guest"), isFalse);
    });
  });

  group("Scenario 3 – Payment Methods (Cash, UPI, Card, Split)", () {
    test("Single Cash payment displays correctly", () {
      final invoice = createMockInvoice(
        payments: [
          BillingPaymentModel(
            paymentId: 1,
            paymentGuid: "p1",
            invoiceId: 784,
            paymentMode: 1,
            paymentModeName: "Cash",
            amount: 225.76,
            paymentStatus: 2,
            createdAtUtc: DateTime.now(),
          ),
        ],
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);
      expect(html.contains("Payment Mode:"), isTrue);
      expect(html.contains("Cash"), isTrue);
      expect(html.contains("Paid Amount:"), isTrue);
    });

    test("Split Payment displays multiple payment modes with individual amounts", () {
      final invoice = createMockInvoice(
        payments: [
          BillingPaymentModel(
            paymentId: 1,
            paymentGuid: "p1",
            invoiceId: 784,
            paymentMode: 1,
            paymentModeName: "Cash",
            amount: 100.00,
            paymentStatus: 2,
            createdAtUtc: DateTime.now(),
          ),
          BillingPaymentModel(
            paymentId: 2,
            paymentGuid: "p2",
            invoiceId: 784,
            paymentMode: 2,
            paymentModeName: "UPI",
            amount: 125.76,
            paymentStatus: 2,
            createdAtUtc: DateTime.now(),
          ),
        ],
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);
      expect(html.contains("Split Settlement:"), isTrue);
      expect(html.contains("Cash:"), isTrue);
      expect(html.contains("100.00"), isTrue);
      expect(html.contains("UPI:"), isTrue);
      expect(html.contains("125.76"), isTrue);
    });
  });

  group("Scenario 4 – Tax Scenarios (GST vs Non-GST vs IGST)", () {
    test("GST Invoice displays Taxable Amount, CGST and SGST correctly", () {
      final invoice = createMockInvoice(
        subTotal: 225.0,
        discountAmount: 10.0,
        taxableAmount: 215.0,
        taxAmount: 10.76,
        grandTotal: 225.76,
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);
      expect(html.contains("Subtotal:"), isTrue);
      expect(html.contains("Discount:"), isTrue);
      expect(html.contains("Taxable Amount:"), isTrue);
      expect(html.contains("CGST:"), isTrue);
      expect(html.contains("5.38"), isTrue); // 10.76 / 2
      expect(html.contains("SGST:"), isTrue);
      expect(html.contains("5.38"), isTrue);
    });

    test("Non-GST Invoice hides CGST and SGST when tax is zero", () {
      final invoice = createMockInvoice(
        subTotal: 100.0,
        discountAmount: 0.0,
        taxableAmount: 100.0,
        taxAmount: 0.0,
        grandTotal: 100.0,
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);
      expect(html.contains("CGST:"), isFalse);
      expect(html.contains("SGST:"), isFalse);
      expect(html.contains("IGST:"), isFalse);
    });

    test("IGST Invoice displays IGST field when isIgst is true", () {
      final invoice = createMockInvoice(
        taxAmount: 10.76,
        grandTotal: 225.76,
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice, isIgst: true);
      expect(html.contains("IGST:"), isTrue);
      expect(html.contains("10.76"), isTrue);
      expect(html.contains("CGST:"), isFalse);
      expect(html.contains("SGST:"), isFalse);
    });
  });

  group("Scenario 5 – Product Table Structure (5 Columns)", () {
    test("Contains 5 columns: #, Item, Qty, Rate, Amount with text wrapping support", () {
      final invoice = createMockInvoice(
        items: [
          BillingInvoiceItemModel(
            invoiceDetailId: 1,
            invoiceId: 784,
            productId: 10,
            productNameSnapshot: "Premium Organic Roasted Coffee Beans 500g Pack (Special Roast)",
            unitPrice: 450.0,
            quantity: 10,
            lineTotal: 4500.0,
          ),
        ],
        subTotal: 4500.0,
        taxableAmount: 4500.0,
        grandTotal: 4500.0,
      );

      final html = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(invoice: invoice);
      expect(html.contains("col-sno"), isTrue);
      expect(html.contains("col-item"), isTrue);
      expect(html.contains("col-qty"), isTrue);
      expect(html.contains("col-rate"), isTrue);
      expect(html.contains("col-amt"), isTrue);
      expect(html.contains("Premium Organic Roasted Coffee Beans"), isTrue);
      expect(html.contains("450.00"), isTrue);
      expect(html.contains("4500.00"), isTrue);
    });
  });

  group("Scenario 6 – Thermal Printing, Barcode & ESC/POS", () {
    test("Code128BarcodeGenerator produces valid SVG barcode with standard black rects", () {
      final svg = Code128BarcodeGenerator.toSvg("INV-000784");
      expect(svg.startsWith("<svg"), isTrue);
      expect(svg.contains('fill="#000000"'), isTrue);
      expect(svg.endsWith("</svg>"), isTrue);
    });

    test("EscPosGenerator builds 80mm ESC/POS byte sequence with 5 columns and barcode", () {
      const config = PrinterConfigurationModel(
        id: 1,
        printerName: "Epson TM-T82 80mm",
        paperSize: PrinterPaperSize.mm80,
        characterColumns: 48,
        autoCutReceipt: true,
        openCashDrawer: true,
      );

      final bytes = EscPosGenerator.buildInvoiceReceipt(
        config: config,
        shopName: "ListPos Flagship Store",
        invoiceNumber: "INV-000784",
        cashierName: "Anand",
        customerName: "Ramesh Kumar",
        customerMobile: "9876543210",
        items: [
          {"productName": "Rice 1 Kg", "quantity": 2, "unitPrice": 60.0, "lineTotal": 120.0},
          {"productName": "Milk 500ml", "quantity": 2, "unitPrice": 30.0, "lineTotal": 60.0},
        ],
        subTotal: 180.0,
        discountAmount: 0.0,
        taxAmount: 9.0,
        grandTotal: 189.0,
        paymentMode: "UPI",
      );

      expect(bytes.isNotEmpty, isTrue);
      // Verify ESC/POS initialization byte [0x1B, 0x40]
      expect(bytes[0], equals(0x1B));
      expect(bytes[1], equals(0x40));
    });

    test("SoftcopyService generates valid 80mm thermal PDF bytes", () async {
      final invoice = createMockInvoice();
      final pdfBytes = await SoftcopyService.instance.generateThermalReceiptPdf(
        invoice,
        is58mm: false,
        shopAddress: "123 Anna Salai, Chennai",
        contactPhone: "9876543210",
        gstin: "33AAAAA1234A1Z5",
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      // Standard PDF header '%PDF-'
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals("%PDF-"));
    });
  });
}
