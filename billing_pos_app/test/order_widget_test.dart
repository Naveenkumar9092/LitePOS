import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/orders/presentation/widgets/cancel_order_dialog.dart";
import "package:billing_pos_app/features/orders/presentation/widgets/order_details_dialog.dart";

void main() {
  group("Order Widgets Tests", () {
    final testOrder = OrderModel(
      id: 1,
      orderGuid: "test-guid-1",
      orderNumber: "ORD-20261113-0001",
      customerId: 5,
      customerName: "Sneha Reddy",
      customerMobile: "9876500000",
      orderType: OrderTypeEnum.counterSale,
      orderStatus: OrderStatusEnum.newOrder,
      subTotal: 250.0,
      discountAmount: 10.0,
      taxAmount: 12.0,
      grandTotal: 252.0,
      cashierUsername: "cashier1",
      createdAt: DateTime.utc(2026, 11, 13, 11, 0, 0),
      details: [
        OrderDetailModel(
          id: 1,
          orderId: 1,
          productId: 10,
          productName: "Paneer Sandwich",
          unitPrice: 150.0,
          quantity: 1,
          discountAmount: 10.0,
          taxPercentage: 5.0,
          taxAmount: 7.0,
          lineTotal: 147.0,
        ),
        OrderDetailModel(
          id: 2,
          orderId: 1,
          productId: 11,
          productName: "Mango Smoothie",
          unitPrice: 100.0,
          quantity: 1,
          discountAmount: 0.0,
          taxPercentage: 5.0,
          taxAmount: 5.0,
          lineTotal: 105.0,
        ),
      ],
    );

    testWidgets("OrderDetailsDialog renders order details, items and confirm button", (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderDetailsDialog(order: testOrder),
            ),
          ),
        ),
      );

      expect(find.text("ORD-20261113-0001"), findsOneWidget);
      expect(find.text("New"), findsOneWidget);
      expect(find.text("Sneha Reddy (9876500000)"), findsOneWidget);
      expect(find.text("Paneer Sandwich"), findsOneWidget);
      expect(find.text("Mango Smoothie"), findsOneWidget);
      expect(find.text("₹252.00"), findsWidgets);
      expect(find.text("Confirm Order"), findsOneWidget);
      expect(find.text("Cancel Order"), findsOneWidget);
    });

    testWidgets("CancelOrderDialog displays quick reasons and validates empty input", (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancelOrderDialog(
              order: testOrder,
              onConfirm: (reason) async => true,
            ),
          ),
        ),
      );

      expect(find.text("Cancel Order"), findsOneWidget);
      expect(find.text("Customer changed mind"), findsOneWidget);
      expect(find.text("Product out of stock"), findsOneWidget);

      // Attempt to confirm without reason
      await tester.tap(find.text("Confirm Cancellation"));
      await tester.pump();

      expect(find.text("Please enter a cancellation reason."), findsOneWidget);

      // Tap a quick reason
      await tester.tap(find.text("Customer changed mind"));
      await tester.pump();

      expect(find.text("Customer changed mind"), findsWidgets);
    });
  });
}

