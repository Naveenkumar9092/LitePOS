import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/payments/models/payment_models.dart";

void main() {
  group("Payment Models & Enums Tests", () {
    test("PaymentModeEnum maps integers, strings and labels correctly", () {
      expect(PaymentModeEnum.fromValue(1), PaymentModeEnum.cash);
      expect(PaymentModeEnum.fromValue("Cash"), PaymentModeEnum.cash);
      expect(PaymentModeEnum.fromValue(2), PaymentModeEnum.upi);
      expect(PaymentModeEnum.fromValue("UPI"), PaymentModeEnum.upi);
      expect(PaymentModeEnum.fromValue(3), PaymentModeEnum.card);
      expect(PaymentModeEnum.fromValue("Card"), PaymentModeEnum.card);
      expect(PaymentModeEnum.fromValue(4), PaymentModeEnum.split);
      expect(PaymentModeEnum.fromValue("Split"), PaymentModeEnum.split);
    });

    test("PaymentStatusEnum maps statuses correctly", () {
      expect(PaymentStatusEnum.fromValue(1), PaymentStatusEnum.pending);
      expect(PaymentStatusEnum.fromValue(2), PaymentStatusEnum.paid);
      expect(PaymentStatusEnum.fromValue(3), PaymentStatusEnum.partiallyPaid);
      expect(PaymentStatusEnum.fromValue(4), PaymentStatusEnum.refunded);
    });

    test("PaymentTransactionModel deserializes JSON correctly", () {
      final json = {
        "id": 10,
        "paymentGuid": "pay-guid-123",
        "invoiceId": 55,
        "invoiceNumber": "INV-20261113-0001",
        "paymentMode": 2, // UPI
        "paymentModeName": "UPI",
        "amount": 450.0,
        "transactionReference": "UPI-UTR-990011",
        "paymentStatus": 2, // Paid
        "createdAtUtc": "2026-11-13T10:15:00Z",
        "cashierUsername": "cashier1",
        "customerName": "Ramesh Kumar"
      };

      final payment = PaymentTransactionModel.fromJson(json);

      expect(payment.id, 10);
      expect(payment.paymentGuid, "pay-guid-123");
      expect(payment.invoiceId, 55);
      expect(payment.invoiceNumber, "INV-20261113-0001");
      expect(payment.paymentMode, PaymentModeEnum.upi);
      expect(payment.amount, 450.0);
      expect(payment.transactionReference, "UPI-UTR-990011");
      expect(payment.paymentStatus, PaymentStatusEnum.paid);
      expect(payment.customerName, "Ramesh Kumar");

      final outJson = payment.toJson();
      expect(outJson["amount"], 450.0);
      expect(outJson["paymentMode"], 2);
    });

    test("PaymentReconciliationModel parses reconciliation JSON properly", () {
      final json = {
        "date": "2026-11-13T00:00:00Z",
        "openingFloat": 1500.0,
        "cashCollected": 3500.0,
        "upiCollected": 4200.0,
        "cardCollected": 2100.0,
        "totalRefunds": 250.0,
        "netCollected": 9550.0,
        "totalTransactions": 28,
        "expectedCashInDrawer": 4750.0,
        "actualCashInDrawer": 4750.0,
        "cashDifference": 0.0,
        "isRegisterOpen": true,
        "currentSessionGuid": "session-123"
      };

      final recon = PaymentReconciliationModel.fromJson(json);

      expect(recon.openingFloat, 1500.0);
      expect(recon.cashCollected, 3500.0);
      expect(recon.upiCollected, 4200.0);
      expect(recon.cardCollected, 2100.0);
      expect(recon.totalRefunds, 250.0);
      expect(recon.netCollected, 9550.0);
      expect(recon.expectedCashInDrawer, 4750.0);
      expect(recon.isRegisterOpen, true);
    });

    test("CashRegisterSessionModel parses session JSON properly", () {
      final json = {
        "id": 1,
        "sessionGuid": "sess-guid",
        "cashierUsername": "cashier1",
        "deviceId": "POS-01",
        "openingFloat": 1000.0,
        "openingTimeUtc": "2026-11-13T09:00:00Z",
        "closingTimeUtc": "2026-11-13T17:00:00Z",
        "actualCash": 2500.0,
        "expectedCash": 2500.0,
        "discrepancy": 0.0,
        "isOpen": false
      };

      final session = CashRegisterSessionModel.fromJson(json);

      expect(session.id, 1);
      expect(session.openingFloat, 1000.0);
      expect(session.actualCash, 2500.0);
      expect(session.expectedCash, 2500.0);
      expect(session.discrepancy, 0.0);
      expect(session.isOpen, false);
    });
  });
}

