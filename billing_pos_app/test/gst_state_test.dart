import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/gst/models/gst_models.dart";
import "package:billing_pos_app/features/gst/presentation/gst_state.dart";

void main() {
  group("GstState Tests", () {
    test("GstState initializes with proper defaults", () {
      final state = GstState();
      expect(state.isLoading, false);
      expect(state.errorMessage, null);
      expect(state.taxes, isEmpty);
      expect(state.hsnSacs, isEmpty);
      expect(state.creditNotes, isEmpty);
      expect(state.gstConfig, null);
      expect(state.gstSummary, null);
    });

    test("GstState copyWith updates state fields properly", () {
      final state = GstState();
      const tax = TaxModel(
        id: 1,
        taxName: "GST 5%",
        ratePercentage: 5.0,
        cgstPercentage: 2.5,
        sgstPercentage: 2.5,
        igstPercentage: 5.0,
        isActive: true,
        isDefault: true,
        isTaxInclusiveDefault: true,
      );

      final updated = state.copyWith(
        isLoading: true,
        taxes: [tax],
        successMessage: "Tax saved",
      );

      expect(updated.isLoading, true);
      expect(updated.taxes.length, 1);
      expect(updated.taxes.first.taxName, "GST 5%");
      expect(updated.successMessage, "Tax saved");
    });
  });
}

