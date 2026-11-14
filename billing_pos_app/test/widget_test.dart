import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";

void main() {
  group("Core Utilities Tests", () {
    test("CurrencyFormatter formats amounts in Indian Rupees correctly", () {
      expect(CurrencyFormatter.format(120), "₹120.00");
      expect(CurrencyFormatter.format(0), "₹0.00");
      expect(CurrencyFormatter.format(null), "₹0.00");
    });

    test("DateFormatter parses and formats ISO UTC string", () {
      final utcDate = DateTime.utc(2026, 11, 12, 10, 30, 0);
      final isoString = DateFormatter.formatIsoUtc(utcDate);
      expect(isoString.contains("2026-11-12"), true);

      final parsed = DateFormatter.parseIsoUtc(isoString);
      expect(parsed?.year, 2026);
    });
  });

  group("Shared Widgets Tests", () {
    testWidgets("StatusBadge displays label properly", (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: "TEST READY",
              type: BadgeType.success,
            ),
          ),
        ),
      );

      expect(find.text("TEST READY"), findsOneWidget);
    });

    testWidgets("AppButton displays text and triggers callback", (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: "Click Me",
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text("Click Me"), findsOneWidget);
      await tester.tap(find.text("Click Me"));
      await tester.pump();

      expect(tapped, true);
    });
  });
}

