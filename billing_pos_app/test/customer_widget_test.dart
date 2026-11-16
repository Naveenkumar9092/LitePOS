import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/customers/models/customer_model.dart";
import "package:billing_pos_app/features/customers/presentation/widgets/customer_form_dialog.dart";

void main() {
  Widget createWidgetForTesting(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group("Customer Widgets Tests", () {
    testWidgets("CustomerFormDialog renders creation fields and switches", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      await tester.pumpWidget(createWidgetForTesting(const CustomerFormDialog()));
      await tester.pumpAndSettle();

      expect(find.text("Add New Customer"), findsOneWidget);
      expect(find.text("Customer Name *"), findsOneWidget);
      expect(find.text("Mobile Number (10 Digits) *"), findsOneWidget);
      expect(find.text("WhatsApp number same as mobile"), findsOneWidget);
      expect(find.text("WhatsApp Invoicing Consent"), findsOneWidget);
      expect(find.text("Email Invoicing Consent"), findsOneWidget);
      expect(find.text("Save Customer"), findsOneWidget);
    });

    testWidgets("CustomerFormDialog pre-fills in edit mode", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      final customer = CustomerModel(
        id: 1,
        customerGuid: "guid-1",
        customerName: "Karthik Raja",
        mobileNumber: "9876543201",
        whatsAppNumber: "9876543201",
        email: "karthik@example.com",
        address: "T. Nagar, Chennai",
        gstin: "33AAAAA0000A1Z5",
        emailConsent: true,
        whatsAppConsent: true,
        totalInvoicesCount: 3,
        totalSpent: 900.0,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetForTesting(CustomerFormDialog(customer: customer)));
      await tester.pumpAndSettle();

      expect(find.text("Edit Customer Profile"), findsOneWidget);
      expect(find.text("Karthik Raja"), findsWidgets);
      expect(find.text("9876543201"), findsWidgets);
      expect(find.text("karthik@example.com"), findsWidgets);
      expect(find.text("33AAAAA0000A1Z5"), findsWidgets);
      expect(find.text("Active Account"), findsOneWidget);
      expect(find.text("Save Changes"), findsOneWidget);
    });

    testWidgets("CustomerFormDialog validates empty inputs and invalid mobile", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      await tester.pumpWidget(createWidgetForTesting(const CustomerFormDialog()));
      await tester.pumpAndSettle();

      // Tap save without filling form
      final saveBtn = find.text("Save Customer");
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text("Customer name is required."), findsOneWidget);
      expect(find.text("Mobile number is required."), findsOneWidget);

      // Enter invalid mobile
      await tester.enterText(find.byType(TextFormField).at(1), "12345");
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text("Enter valid 10-digit Indian mobile."), findsOneWidget);
    });
  });
}
