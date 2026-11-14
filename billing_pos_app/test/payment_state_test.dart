import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/payments/models/payment_models.dart";
import "package:billing_pos_app/features/payments/presentation/payment_state.dart";

void main() {
  group("PaymentState Filtering Tests", () {
    final pay1 = PaymentTransactionModel(
      id: 1,
      paymentGuid: "g1",
      invoiceId: 101,
      invoiceNumber: "INV-20261113-0001",
      paymentMode: PaymentModeEnum.cash,
      paymentModeName: "Cash",
      amount: 250.0,
      paymentStatus: PaymentStatusEnum.paid,
      createdAt: DateTime.now(),
      customerName: "Rahul Sharma",
    );

    final pay2 = PaymentTransactionModel(
      id: 2,
      paymentGuid: "g2",
      invoiceId: 102,
      invoiceNumber: "INV-20261113-0002",
      paymentMode: PaymentModeEnum.upi,
      paymentModeName: "UPI",
      amount: 450.0,
      transactionReference: "UPI-UTR-889900",
      paymentStatus: PaymentStatusEnum.paid,
      createdAt: DateTime.now(),
      customerName: "Priya Patel",
    );

    final pay3 = PaymentTransactionModel(
      id: 3,
      paymentGuid: "g3",
      invoiceId: 103,
      invoiceNumber: "INV-20261113-0003",
      paymentMode: PaymentModeEnum.card,
      paymentModeName: "Card",
      amount: 1200.0,
      transactionReference: "AUTH-CARD-4455",
      paymentStatus: PaymentStatusEnum.paid,
      createdAt: DateTime.now(),
      customerName: "Amit Verma",
    );

    test("displayedPayments returns all transactions when no filter is set", () {
      final state = PaymentState(payments: [pay1, pay2, pay3]);
      expect(state.displayedPayments.length, 3);
    });

    test("displayedPayments filters by payment mode properly", () {
      final state = PaymentState(payments: [pay1, pay2, pay3], filterMode: PaymentModeEnum.upi);
      expect(state.displayedPayments.length, 1);
      expect(state.displayedPayments.first.id, 2);
    });

    test("displayedPayments searches by invoice number, reference, or customer", () {
      final searchInv = PaymentState(payments: [pay1, pay2, pay3], searchQuery: "0002");
      expect(searchInv.displayedPayments.length, 1);
      expect(searchInv.displayedPayments.first.id, 2);

      final searchRef = PaymentState(payments: [pay1, pay2, pay3], searchQuery: "AUTH-CARD");
      expect(searchRef.displayedPayments.length, 1);
      expect(searchRef.displayedPayments.first.id, 3);

      final searchCust = PaymentState(payments: [pay1, pay2, pay3], searchQuery: "Rahul");
      expect(searchCust.displayedPayments.length, 1);
      expect(searchCust.displayedPayments.first.id, 1);
    });

    test("PaymentState copyWith updates fields properly", () {
      const state = PaymentState();
      final updated = state.copyWith(
        isLoading: true,
        searchQuery: "INV",
        filterMode: PaymentModeEnum.cash,
      );

      expect(updated.isLoading, true);
      expect(updated.searchQuery, "INV");
      expect(updated.filterMode, PaymentModeEnum.cash);
    });
  });
}

