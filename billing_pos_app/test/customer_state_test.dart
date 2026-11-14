import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/customers/models/customer_model.dart";
import "package:billing_pos_app/features/customers/presentation/customer_state.dart";

void main() {
  group("CustomerState Tests", () {
    test("CustomerState defaults are properly initialized", () {
      const state = CustomerState();
      expect(state.isLoading, false);
      expect(state.isActionLoading, false);
      expect(state.customers, isEmpty);
      expect(state.searchQuery, "");
      expect(state.page, 1);
      expect(state.pageSize, 20);
      expect(state.totalCount, 0);
      expect(state.totalPages, 1);
    });

    test("CustomerState copyWith updates fields properly", () {
      const state = CustomerState();
      final customer = CustomerModel(
        id: 1,
        customerGuid: "guid",
        customerName: "Karthik",
        mobileNumber: "9876543201",
        emailConsent: true,
        whatsAppConsent: true,
        totalInvoicesCount: 2,
        totalSpent: 400.0,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final updated = state.copyWith(
        isLoading: true,
        customers: [customer],
        totalCount: 1,
        searchQuery: "Karthik",
      );

      expect(updated.isLoading, true);
      expect(updated.customers.length, 1);
      expect(updated.totalCount, 1);
      expect(updated.searchQuery, "Karthik");
    });
  });
}

