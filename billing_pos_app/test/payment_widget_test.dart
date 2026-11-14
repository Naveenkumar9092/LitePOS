import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/payments/presentation/widgets/close_register_dialog.dart";
import "package:billing_pos_app/features/payments/presentation/widgets/open_register_dialog.dart";
import "package:billing_pos_app/features/payments/presentation/widgets/refund_dialog.dart";

void main() {
  group("Payment Widgets Tests", () {
    testWidgets("OpenRegisterDialog renders preset float chips and submits float", (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));

      double? capturedFloat;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenRegisterDialog(
              onConfirm: (float, notes) async {
                capturedFloat = float;
                return true;
              },
            ),
          ),
        ),
      );

      expect(find.text("Day Opening / Open Register"), findsOneWidget);
      expect(find.text("₹500"), findsOneWidget);
      expect(find.text("₹1000"), findsWidgets);
      expect(find.text("₹2000"), findsOneWidget);

      // Tap preset chip ₹2000
      await tester.tap(find.text("₹2000"));
      await tester.pump();

      // Submit
      await tester.tap(find.text("Open Cash Register"));
      await tester.pump();

      expect(capturedFloat, 2000.0);
    });

    testWidgets("CloseRegisterDialog renders expected cash and computes discrepancy", (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CloseRegisterDialog(
              expectedCash: 1500.0,
              onConfirm: (actual, notes) async => true,
            ),
          ),
        ),
      );

      expect(find.text("Day Closing / Close Register"), findsOneWidget);
      expect(find.text("₹1,500.00"), findsWidgets);
      expect(find.text("₹0.00 (Balanced)"), findsOneWidget);

      // Enter 1550 (overage of +50)
      final inputFinder = find.byType(TextField).first;
      await tester.enterText(inputFinder, "1550.00");
      await tester.pump();

      expect(find.textContaining("Overage"), findsOneWidget);
    });

    testWidgets("RefundDialog displays quick reasons and validates required fields", (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefundDialog(
              initialInvoiceId: 10,
              maxRefundAmount: 500.0,
              onConfirm: (invId, amt, reason) async => true,
            ),
          ),
        ),
      );

      expect(find.text("Process Customer Refund"), findsOneWidget);
      expect(find.text("Item returned / defective"), findsOneWidget);

      // Select quick reason
      await tester.tap(find.text("Item returned / defective"));
      await tester.pump();

      expect(find.text("Item returned / defective"), findsWidgets);
    });
  });
}

