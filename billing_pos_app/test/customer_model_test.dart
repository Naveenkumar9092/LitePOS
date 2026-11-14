import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/customers/models/customer_model.dart";

void main() {
  group("Customer Model Tests", () {
    test("CustomerModel serializes to and from JSON correctly", () {
      final json = {
        "id": 1,
        "customerGuid": "guid-cust-1",
        "customerName": "Karthik Raja",
        "mobileNumber": "9876543201",
        "whatsAppNumber": "9876543201",
        "email": "karthik@example.com",
        "address": "T. Nagar, Chennai",
        "gstin": "33AAAAA0000A1Z5",
        "emailConsent": true,
        "whatsAppConsent": true,
        "totalInvoicesCount": 5,
        "totalSpent": 1500.0,
        "lastVisitDateUtc": "2026-11-12T15:30:00Z",
        "isActive": true,
        "createdAtUtc": "2026-11-01T10:00:00Z",
      };

      final customer = CustomerModel.fromJson(json);
      expect(customer.id, 1);
      expect(customer.customerName, "Karthik Raja");
      expect(customer.mobileNumber, "9876543201");
      expect(customer.gstin, "33AAAAA0000A1Z5");
      expect(customer.emailConsent, true);
      expect(customer.whatsAppConsent, true);
      expect(customer.totalInvoicesCount, 5);
      expect(customer.totalSpent, 1500.0);

      final map = customer.toJson();
      expect(map["id"], 1);
      expect(map["customerName"], "Karthik Raja");
      expect(map["mobileNumber"], "9876543201");
    });

    test("CustomerModel roundtrip SQLite preserves columns", () {
      final customer = CustomerModel(
        id: 2,
        customerGuid: "guid-2",
        customerName: "Priya Sundaram",
        mobileNumber: "9876543202",
        whatsAppNumber: "9876543202",
        email: "priya@example.com",
        address: "Adyar, Chennai",
        gstin: null,
        emailConsent: true,
        whatsAppConsent: false,
        totalInvoicesCount: 0,
        totalSpent: 0.0,
        isActive: true,
        createdAtUtc: DateTime.utc(2026, 11, 1),
      );

      final sqlite = customer.toSqlite();
      expect(sqlite["CustomerId"], 2);
      expect(sqlite["CustomerName"], "Priya Sundaram");
      expect(sqlite["WhatsAppConsent"], 0);
      expect(sqlite["EmailConsent"], 1);

      final fromSqlite = CustomerModel.fromSqlite(sqlite);
      expect(fromSqlite.id, 2);
      expect(fromSqlite.customerName, "Priya Sundaram");
      expect(fromSqlite.emailConsent, true);
      expect(fromSqlite.whatsAppConsent, false);
    });

    test("CustomerLookupModel parses JSON correctly", () {
      final json = {
        "id": 5,
        "customerName": "Anand Kumar",
        "mobileNumber": "9876543203",
        "gstin": null,
        "email": "anand@example.com",
        "whatsAppNumber": "9876543203",
      };

      final lookup = CustomerLookupModel.fromJson(json);
      expect(lookup.id, 5);
      expect(lookup.customerName, "Anand Kumar");
      expect(lookup.mobileNumber, "9876543203");
    });

    test("CustomerPurchaseHistoryModel parses JSON correctly", () {
      final json = {
        "customerId": 1,
        "customerName": "Karthik Raja",
        "mobileNumber": "9876543201",
        "gstin": "33AAAAA0000A1Z5",
        "totalInvoices": 2,
        "totalSpent": 500.0,
        "firstVisitDateUtc": "2026-11-01T10:00:00Z",
        "lastVisitDateUtc": "2026-11-12T15:00:00Z",
        "invoices": [
          {
            "invoiceId": 10,
            "invoiceNumber": "INV-10",
            "invoiceDateUtc": "2026-11-12T15:00:00Z",
            "grandTotal": 300.0,
            "paymentStatus": "Paid",
            "totalItems": 3,
          }
        ]
      };

      final history = CustomerPurchaseHistoryModel.fromJson(json);
      expect(history.customerId, 1);
      expect(history.totalInvoices, 2);
      expect(history.totalSpent, 500.0);
      expect(history.invoices.length, 1);
      expect(history.invoices.first.grandTotal, 300.0);
    });
  });
}
