import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/billing/presentation/widgets/receipt_preview_dialog.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/reports/models/report_models.dart";
import "package:billing_pos_app/features/reports/presentation/report_state.dart";

void main() {
  group("SoftcopyService Generation Tests", () {
    test("generateInvoicePdf produces valid PDF bytes with standard header", () async {
      final invoice = BillingInvoiceModel(
        invoiceId: 101,
        invoiceGuid: "inv-guid-101",
        invoiceNumber: "INV-2026-0001",
        companyId: 1,
        companyName: "Pooja Sweets & Cafe Pvt Ltd",
        shopId: 1,
        shopName: "Pooja Sweets & Cafe Counter 1",
        cashierId: 3,
        cashierName: "Cashier Priya",
        deviceId: "POS-01",
        customerName: "Rahul Sharma",
        customerMobile: "9840123456",
        invoiceDateUtc: DateTime.utc(2026, 11, 14, 15, 30),
        subTotal: 500.0,
        discountAmount: 50.0,
        taxableAmount: 450.0,
        taxAmount: 22.50,
        grandTotal: 472.50,
        paidAmount: 500.0,
        balanceAmount: 27.50,
        paymentStatus: 2,
        invoiceStatus: 2,
        syncStatus: 1,
        createdAtUtc: DateTime.utc(2026, 11, 14, 15, 30),
        items: [
          BillingInvoiceItemModel(
            invoiceDetailId: 1,
            invoiceId: 101,
            productId: 10,
            productNameSnapshot: "Kaju Katli (250g)",
            unitPrice: 250.0,
            quantity: 2,
            taxPercentage: 5.0,
            taxAmount: 22.50,
            lineTotal: 472.50,
          ),
        ],
        payments: [
          BillingPaymentModel(
            paymentId: 1,
            paymentGuid: "pay-1",
            invoiceId: 101,
            paymentMode: 1,
            paymentModeName: "Cash",
            amount: 500.0,
            paymentStatus: 2,
            createdAtUtc: DateTime.now(),
          ),
        ],
      );

      final bytes = await SoftcopyService.instance.generateInvoicePdf(invoice);

      expect(bytes.isNotEmpty, isTrue);
      // Standard PDF header '%PDF-'
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, equals("%PDF-"));
    });

    test("generateOrderInvoicePdf produces valid PDF bytes with standard header", () async {
      final order = OrderModel(
        id: 201,
        orderGuid: "ord-guid-201",
        orderNumber: "ORD-2026-0002",
        orderType: OrderTypeEnum.takeaway,
        orderStatus: OrderStatusEnum.completed,
        cashierUsername: "admin_user",
        customerName: "Kavitha",
        customerMobile: "9876543210",
        createdAt: DateTime.utc(2026, 11, 14, 16, 00),
        subTotal: 300.0,
        discountAmount: 0.0,
        taxAmount: 15.0,
        grandTotal: 315.0,
        details: [
          OrderDetailModel(
            id: 1,
            orderId: 201,
            productId: 5,
            productName: "Motichoor Ladoo",
            unitPrice: 150.0,
            quantity: 2,
            taxPercentage: 5.0,
            taxAmount: 15.0,
            lineTotal: 315.0,
          ),
        ],
      );

      final bytes = await SoftcopyService.instance.generateOrderInvoicePdf(order);

      expect(bytes.isNotEmpty, isTrue);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, equals("%PDF-"));
    });

    test("generateReportPdf and CSV export produce valid softcopy outputs", () async {
      final now = DateTime.now();
      final filter = ReportFilterModel(
        rangeType: ReportDateRangeType.today,
        fromDateUtc: now.subtract(const Duration(days: 7)),
        toDateUtc: now,
      );

      final summary = SalesReportSummaryModel(
        fromDateUtc: now.subtract(const Duration(days: 7)),
        toDateUtc: now,
        totalInvoices: 25,
        totalActiveInvoices: 24,
        totalCancelledInvoices: 1,
        grossSales: 15000.0,
        totalDiscount: 500.0,
        netSales: 14500.0,
        totalTax: 725.0,
        grandTotalSales: 15225.0,
        totalRefunds: 0.0,
        netRevenue: 15225.0,
        totalCashCollected: 8000.0,
        totalUpiCollected: 6000.0,
        totalCardCollected: 1225.0,
        totalDueOutstanding: 0.0,
        averageOrderValue: 609.0,
      );

      final state = ReportState(
        filter: filter,
        summary: summary,
        dailySales: [
          DailySalesModel(
            date: DateTime.now(),
            invoiceCount: 10,
            grossSales: 6000.0,
            discountAmount: 200.0,
            taxAmount: 290.0,
            netSales: 6090.0,
            cashAmount: 3000.0,
            upiAmount: 3090.0,
            cardAmount: 0.0,
          ),
        ],
        productSales: const [
          ProductSalesReportModel(
            productId: 1,
            productName: "Gulab Jamun",
            categoryName: "Sweets",
            quantitySold: 40,
            totalRevenue: 2400.0,
            totalTax: 120.0,
            percentageOfSales: 16.0,
          ),
        ],
        categorySales: const [
          CategorySalesReportModel(
            categoryId: 1,
            categoryName: "Sweets",
            totalQuantitySold: 120,
            totalRevenue: 8500.0,
            percentageOfSales: 56.0,
          ),
        ],
        paymentBreakdown: const [
          PaymentModeBreakdownModel(
            paymentMode: "Cash",
            transactionCount: 15,
            totalAmount: 8000.0,
            percentage: 52.5,
          ),
        ],
      );

      // PDF Softcopy test
      final pdfBytes = await SoftcopyService.instance.generateReportPdf(state: state);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(ascii.decode(pdfBytes.sublist(0, 5)), equals("%PDF-"));

      // CSV Softcopy test
      final csv = SoftcopyService.instance.generateReportCsv(state);
      expect(csv, contains("Business Performance Report"));
      expect(csv, contains("EXECUTIVE SUMMARY"));
      expect(csv, contains("Gross Sales,15000.0"));
      expect(csv, contains("Gulab Jamun"));
      expect(csv, contains("Sweets"));
    });
  });

  group("ReceiptPreviewDialog Softcopy UI Tests", () {
    testWidgets("renders Softcopy PDF and Save Softcopy actions", (tester) async {
      final invoice = BillingInvoiceModel(
        invoiceId: 101,
        invoiceGuid: "guid-1",
        invoiceNumber: "INV-1001",
        companyId: 1,
        companyName: "Pooja Sweets",
        shopId: 1,
        shopName: "Counter 1",
        cashierId: 1,
        cashierName: "Priya",
        deviceId: "POS-01",
        invoiceDateUtc: DateTime.now(),
        subTotal: 100.0,
        discountAmount: 0.0,
        taxableAmount: 100.0,
        taxAmount: 5.0,
        grandTotal: 105.0,
        paidAmount: 105.0,
        balanceAmount: 0.0,
        paymentStatus: 2,
        invoiceStatus: 2,
        syncStatus: 1,
        createdAtUtc: DateTime.now(),
        items: [
          BillingInvoiceItemModel(
            invoiceDetailId: 1,
            invoiceId: 101,
            productId: 1,
            productNameSnapshot: "Ladoo",
            unitPrice: 50.0,
            quantity: 2,
            lineTotal: 105.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptPreviewDialog(invoice: invoice),
          ),
        ),
      );

      expect(find.text("Invoice Softcopy (PDF)"), findsOneWidget);
      expect(find.text("Save Softcopy"), findsOneWidget);
      expect(find.text("Print Receipt"), findsOneWidget);
    });
  });
}
