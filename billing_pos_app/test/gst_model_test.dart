import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/gst/models/gst_models.dart";

void main() {
  group("GST Models & Calculations Tests", () {
    test("TaxModel serializes and deserializes JSON and SQLite correctly", () {
      final json = {
        "id": 2,
        "taxName": "GST 5%",
        "ratePercentage": 5.0,
        "cgstPercentage": 2.5,
        "sgstPercentage": 2.5,
        "igstPercentage": 5.0,
        "isActive": true,
        "isDefault": true,
        "isTaxInclusiveDefault": true,
      };

      final model = TaxModel.fromJson(json);
      expect(model.id, 2);
      expect(model.taxName, "GST 5%");
      expect(model.ratePercentage, 5.0);
      expect(model.cgstPercentage, 2.5);
      expect(model.sgstPercentage, 2.5);
      expect(model.igstPercentage, 5.0);
      expect(model.isActive, true);
      expect(model.isDefault, true);

      final sqliteMap = model.toSqlite();
      expect(sqliteMap["TaxId"], 2);
      expect(sqliteMap["IsDefault"], 1);

      final fromSqlite = TaxModel.fromSqlite(sqliteMap);
      expect(fromSqlite.taxName, "GST 5%");
      expect(fromSqlite.isDefault, true);
    });

    test("HsnSacModel serializes to and from SQLite map correctly", () {
      final model = const HsnSacModel(
        id: 1,
        code: "2106",
        description: "Food preparations n.e.c (Sweets, snacks)",
        type: "HSN",
        defaultGstRate: 5.0,
        isActive: true,
      );

      final map = model.toSqlite();
      expect(map["Code"], "2106");
      expect(map["Type"], "HSN");
      expect(map["IsActive"], 1);

      final fromMap = HsnSacModel.fromSqlite(map);
      expect(fromMap.code, "2106");
      expect(fromMap.defaultGstRate, 5.0);
    });

    test("GstConfigurationModel parses JSON properly", () {
      final json = {
        "id": 1,
        "gstin": "33AAAAA0000A1Z5",
        "legalName": "LitePOS Tech Pvt Ltd",
        "tradeName": "LitePOS Cafe",
        "stateName": "Tamil Nadu",
        "stateCode": "33",
        "isCompositionScheme": false,
        "defaultPricingIsTaxInclusive": true,
        "invoiceTermsAndConditions": "Terms here",
        "invoiceHeader": "Welcome",
        "invoiceFooter": "Thank you",
        "showHsnSummaryOnReceipt": true,
        "showTaxBreakupOnReceipt": true,
      };

      final config = GstConfigurationModel.fromJson(json);
      expect(config.gstin, "33AAAAA0000A1Z5");
      expect(config.stateCode, "33");
      expect(config.defaultPricingIsTaxInclusive, true);
      expect(config.showHsnSummaryOnReceipt, true);
    });

    test("CreditNoteModel parses JSON correctly with items", () {
      final json = {
        "id": 1,
        "creditNoteGuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "creditNoteNumber": "CN-202611-0001",
        "invoiceId": 10,
        "invoiceNumber": "INV-202611-0001",
        "customerId": 2,
        "customerName": "Retail Walk-in",
        "customerGstin": null,
        "creditNoteDateUtc": "2026-11-13T10:00:00Z",
        "reason": "Customer dissatisfied with food quality",
        "noteType": "CreditNote",
        "taxableAmount": 95.24,
        "cgstAmount": 2.38,
        "sgstAmount": 2.38,
        "igstAmount": 0.0,
        "totalTaxAmount": 4.76,
        "grandTotal": 100.0,
        "status": "Issued",
        "items": [
          {
            "productId": 1,
            "productName": "Espresso Coffee",
            "hsnCode": "2106",
            "quantity": 1,
            "unitPrice": 100.0,
            "taxPercentage": 5.0,
            "taxAmount": 4.76,
            "lineTotal": 100.0,
            "reason": "Cold coffee"
          }
        ]
      };

      final note = CreditNoteModel.fromJson(json);
      expect(note.creditNoteNumber, "CN-202611-0001");
      expect(note.noteType, "CreditNote");
      expect(note.grandTotal, 100.0);
      expect(note.cgstAmount, 2.38);
      expect(note.sgstAmount, 2.38);
      expect(note.items.length, 1);
      expect(note.items.first.productName, "Espresso Coffee");
    });

    test("GstSummaryModel aggregates B2B, B2C, HSN and Credit notes JSON properly", () {
      final json = {
        "fromUtc": "2026-11-01T00:00:00Z",
        "toUtc": "2026-11-30T23:59:59Z",
        "companyGstin": "33AAAAA0000A1Z5",
        "legalName": "LitePOS Tech Pvt Ltd",
        "stateCode": "33",
        "b2cSummary": {
          "totalInvoices": 10,
          "taxableValue": 1000.0,
          "cgstAmount": 25.0,
          "sgstAmount": 25.0,
          "igstAmount": 0.0,
          "totalTax": 50.0,
          "grandTotal": 1050.0,
        },
        "b2bSummary": {
          "totalInvoices": 2,
          "taxableValue": 2000.0,
          "cgstAmount": 0.0,
          "sgstAmount": 0.0,
          "igstAmount": 100.0,
          "totalTax": 100.0,
          "grandTotal": 2100.0,
          "invoices": [
            {
              "invoiceId": 5,
              "invoiceNumber": "INV-5",
              "invoiceDateUtc": "2026-11-10T12:00:00Z",
              "customerName": "Corporate Corp",
              "customerGstin": "29XXXXX9999X1Z1",
              "taxableValue": 2000.0,
              "cgstAmount": 0.0,
              "sgstAmount": 0.0,
              "igstAmount": 100.0,
              "totalTax": 100.0,
              "grandTotal": 2100.0,
            }
          ]
        },
        "hsnSummary": [
          {
            "hsnCode": "2106",
            "description": "Food & Snacks",
            "totalQuantity": 25,
            "taxableValue": 3000.0,
            "cgstAmount": 75.0,
            "sgstAmount": 75.0,
            "igstAmount": 0.0,
            "totalTax": 150.0,
          }
        ],
        "creditNotesSummary": {
          "totalCount": 1,
          "totalTaxableReduced": 100.0,
          "totalTaxReduced": 5.0,
          "netSalesLiability": 2900.0,
        }
      };

      final summary = GstSummaryModel.fromJson(json);
      expect(summary.companyGstin, "33AAAAA0000A1Z5");
      expect(summary.b2cSummary.totalInvoices, 10);
      expect(summary.b2bSummary.invoices.length, 1);
      expect(summary.b2bSummary.invoices.first.customerGstin, "29XXXXX9999X1Z1");
      expect(summary.hsnSummary.first.hsnCode, "2106");
      expect(summary.creditNotesSummary.netSalesLiability, 2900.0);
    });
  });
}

