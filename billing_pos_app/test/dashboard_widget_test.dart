import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/components/offline_status_indicator.dart";
import "package:billing_pos_app/features/dashboard/presentation/components/payment_summary_card.dart";
import "package:billing_pos_app/features/dashboard/presentation/components/recent_transactions_widget.dart";
import "package:billing_pos_app/features/dashboard/presentation/components/sales_summary_cards.dart";
import "package:billing_pos_app/features/dashboard/presentation/components/shift_summary_card.dart";

void main() {
  group("Dashboard Widgets Tests", () {
    testWidgets("SalesSummaryCards displays sales metrics properly", (tester) async {
      final summary = SalesSummaryModel(
        totalSales: 12500.0,
        totalInvoices: 15,
        averageBillValue: 833.33,
        totalDiscount: 150.0,
        totalTax: 625.0,
        netSales: 11875.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SalesSummaryCards(summary: summary),
          ),
        ),
      );

      expect(find.text("Total Sales"), findsOneWidget);
      expect(find.text("Avg Bill Value"), findsOneWidget);
      expect(find.text("Tax Collected"), findsOneWidget);
      expect(find.text("Net Sales"), findsOneWidget);
      expect(find.text("15 Invoices"), findsOneWidget);
    });

    testWidgets("PaymentSummaryCard displays breakdown properly", (tester) async {
      final payment = PaymentSummaryModel(
        cashTotal: 5000.0,
        upiTotal: 4000.0,
        cardTotal: 1000.0,
        otherTotal: 0.0,
        grandTotal: 10000.0,
        cashTransactions: 5,
        upiTransactions: 4,
        cardTransactions: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSummaryCard(summary: payment),
          ),
        ),
      );

      expect(find.text("Payment Breakdown"), findsOneWidget);
      expect(find.text("Cash"), findsOneWidget);
      expect(find.text("UPI / QR"), findsOneWidget);
      expect(find.text("Card / POS Terminal"), findsOneWidget);
    });

    testWidgets("ShiftSummaryCard displays opening float and cash in drawer", (tester) async {
      final shift = ShiftSummaryModel(
        shiftDate: "2026-11-13",
        openingFloat: 1000.0,
        cashCollected: 3500.0,
        cashOnHand: 4500.0,
        billsIssued: 7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShiftSummaryCard(shift: shift),
          ),
        ),
      );

      expect(find.text("Cash Drawer & Shift Summary"), findsOneWidget);
      expect(find.text("Opening Float"), findsOneWidget);
      expect(find.text("Cash Collected"), findsOneWidget);
      expect(find.text("Current Cash in Drawer"), findsOneWidget);
      expect(find.text("ACTIVE SHIFT"), findsOneWidget);
    });

    testWidgets("OfflineStatusIndicator displays online status properly", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusIndicator(
              isOnline: true,
              pendingSyncCount: 0,
            ),
          ),
        ),
      );

      expect(find.text("ONLINE"), findsOneWidget);
    });

    testWidgets("OfflineStatusIndicator displays offline SQLite status and count", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusIndicator(
              isOnline: false,
              pendingSyncCount: 3,
            ),
          ),
        ),
      );

      expect(find.text("OFFLINE (SQLite)"), findsOneWidget);
      expect(find.text("3"), findsOneWidget);
    });

    testWidgets("RecentTransactionsWidget displays transactions correctly", (tester) async {
      final txs = [
        RecentTransactionModel(
          invoiceId: 1,
          invoiceNumber: "INV-001",
          customerName: "Priya Sundaram",
          cashierName: "Cashier",
          totalAmount: 350.0,
          paymentMode: "UPI",
          invoiceStatus: "Active",
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentTransactionsWidget(transactions: txs),
          ),
        ),
      );

      expect(find.text("Recent Invoices"), findsOneWidget);
      expect(find.text("INV-001"), findsOneWidget);
      expect(find.text("UPI"), findsOneWidget);
    });
  });
}

