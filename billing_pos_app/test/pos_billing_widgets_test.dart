import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/billing/presentation/widgets/payment_dialog.dart";
import "package:billing_pos_app/features/billing/presentation/widgets/receipt_preview_dialog.dart";

void main() {
  group("POS Billing Widgets Tests", () {
    testWidgets("PaymentDialog renders total payable and payment mode tabs", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentDialog(totalAmount: 315.0),
          ),
        ),
      );

      expect(find.text("Payment & Settlement"), findsOneWidget);
      expect(find.text("TOTAL PAYABLE"), findsOneWidget);
      expect(find.text("₹315.00"), findsWidgets);
      expect(find.text("Cash"), findsOneWidget);
      expect(find.text("UPI / QR"), findsOneWidget);
      expect(find.text("Card"), findsOneWidget);
      expect(find.text("Complete & Print Invoice"), findsOneWidget);
    });

    testWidgets("ReceiptPreviewDialog renders thermal layout and totals correctly", (tester) async {
      final fixedDate = DateTime.utc(2026, 11, 13, 10, 30, 0);

      final invoice = BillingInvoiceModel(
        invoiceId: 101,
        invoiceGuid: "guid-101",
        invoiceNumber: "INV-20261113-0001",
        companyId: 1,
        companyName: "LitePOS Cafe",
        shopId: 1,
        shopName: "Main Branch",
        cashierId: 1,
        cashierName: "Cashier One",
        deviceId: "POS-TERMINAL-01",
        invoiceDateUtc: fixedDate,
        subTotal: 300.0,
        discountAmount: 0.0,
        taxableAmount: 300.0,
        taxAmount: 15.0,
        grandTotal: 315.0,
        paidAmount: 315.0,
        balanceAmount: 0.0,
        paymentStatus: 2,
        invoiceStatus: 2,
        syncStatus: 1,
        items: [
          BillingInvoiceItemModel(
            invoiceDetailId: 1,
            invoiceId: 101,
            productId: 1,
            productNameSnapshot: "Espresso",
            unitPrice: 100.0,
            quantity: 3,
            lineTotal: 315.0,
          ),
        ],
        payments: [
          BillingPaymentModel(
            paymentId: 1,
            paymentGuid: "pay-1",
            invoiceId: 101,
            paymentMode: 1,
            paymentModeName: "Cash",
            amount: 315.0,
            paymentStatus: 2,
            createdAtUtc: fixedDate,
          ),
        ],
        createdAtUtc: fixedDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptPreviewDialog(invoice: invoice),
          ),
        ),
      );

      expect(find.text("Sale Completed Successfully!"), findsOneWidget);
      expect(find.text("Main Branch"), findsOneWidget);
      expect(find.text("INV-20261113-0001"), findsOneWidget);
      expect(find.text("Espresso"), findsOneWidget);
      expect(find.text("GRAND TOTAL:"), findsOneWidget);
      expect(find.text("Payment Mode: Cash"), findsOneWidget);
      expect(find.text("Print Receipt"), findsOneWidget);
      expect(find.text("New Sale"), findsOneWidget);
    });
  });
}

