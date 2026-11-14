import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/gst/models/gst_models.dart";
import "package:billing_pos_app/features/gst/presentation/widgets/credit_note_dialog.dart";
import "package:billing_pos_app/features/gst/presentation/widgets/hsn_form_dialog.dart";
import "package:billing_pos_app/features/gst/presentation/widgets/tax_form_dialog.dart";

void main() {
  Widget createWidgetForTesting(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group("GST Widgets Tests", () {
    testWidgets("TaxFormDialog renders creation fields and switches", (tester) async {
      await tester.pumpWidget(createWidgetForTesting(const TaxFormDialog()));
      await tester.pumpAndSettle();

      expect(find.text("Create Tax Slab"), findsOneWidget);
      expect(find.text("Tax Slab Name *"), findsOneWidget);
      expect(find.text("Rate Percentage (%) *"), findsOneWidget);
      expect(find.text("Default Tax Slab"), findsOneWidget);
      expect(find.text("Prices Are Tax-Inclusive"), findsOneWidget);
      expect(find.text("Create Tax"), findsOneWidget);
    });

    testWidgets("TaxFormDialog pre-fills existing tax data in edit mode", (tester) async {
      const existing = TaxModel(
        id: 2,
        taxName: "GST 18%",
        ratePercentage: 18.0,
        cgstPercentage: 9.0,
        sgstPercentage: 9.0,
        igstPercentage: 18.0,
        isActive: true,
        isDefault: false,
        isTaxInclusiveDefault: true,
      );

      await tester.pumpWidget(createWidgetForTesting(const TaxFormDialog(tax: existing)));
      await tester.pumpAndSettle();

      expect(find.text("Edit Tax Slab"), findsOneWidget);
      expect(find.text("GST 18%"), findsOneWidget);
      expect(find.text("18.0"), findsOneWidget);
      expect(find.text("Active Status"), findsOneWidget);
      expect(find.text("Save Changes"), findsOneWidget);
    });

    testWidgets("HsnFormDialog renders input fields and dropdown", (tester) async {
      await tester.pumpWidget(createWidgetForTesting(const HsnFormDialog()));
      await tester.pumpAndSettle();

      expect(find.text("Add HSN/SAC Code"), findsOneWidget);
      expect(find.text("Code *"), findsOneWidget);
      expect(find.text("Description *"), findsOneWidget);
      expect(find.text("Default GST Rate (%) *"), findsOneWidget);
      expect(find.text("Add HSN/SAC"), findsOneWidget);
    });

    testWidgets("CreditNoteDialog renders quick reasons and validates empty invoice ID", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      await tester.pumpWidget(createWidgetForTesting(const CreditNoteDialog()));
      await tester.pumpAndSettle();

      expect(find.text("Issue Credit Note"), findsOneWidget);
      expect(find.text("Invoice ID *"), findsOneWidget);
      expect(find.text("Quick Reason Selection:"), findsOneWidget);
      expect(find.text("Sales Return / Returned item"), findsWidgets);
      expect(find.text("Detailed Reason *"), findsOneWidget);

      // Tap issue button without filling invoice ID
      final issueBtn = find.text("Issue CreditNote");
      expect(issueBtn, findsOneWidget);
      await tester.tap(issueBtn);
      await tester.pumpAndSettle();

      expect(find.text("Invoice ID is required."), findsOneWidget);
    });
  });
}
