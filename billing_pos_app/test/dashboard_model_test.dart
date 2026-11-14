import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";

void main() {
  group("Dashboard Models Tests", () {
    test("SalesSummaryModel correctly deserializes and computes metrics", () {
      final json = {
        "totalSales": 15420.50,
        "totalInvoices": 24,
        "averageBillValue": 642.52,
        "totalDiscount": 200.0,
        "totalTax": 771.0,
        "netSales": 14649.50,
      };

      final model = SalesSummaryModel.fromJson(json);

      expect(model.totalSales, 15420.50);
      expect(model.totalInvoices, 24);
      expect(model.averageBillValue, 642.52);
      expect(model.totalDiscount, 200.0);
      expect(model.totalTax, 771.0);
      expect(model.netSales, 14649.50);
    });

    test("PaymentSummaryModel correctly deserializes breakdown", () {
      final json = {
        "cashTotal": 6500.0,
        "upiTotal": 7200.0,
        "cardTotal": 1720.50,
        "otherTotal": 0.0,
        "grandTotal": 15420.50,
        "cashTransactions": 10,
        "upiTransactions": 11,
        "cardTransactions": 3,
      };

      final model = PaymentSummaryModel.fromJson(json);

      expect(model.cashTotal, 6500.0);
      expect(model.upiTotal, 7200.0);
      expect(model.cardTotal, 1720.50);
      expect(model.grandTotal, 15420.50);
      expect(model.cashTransactions, 10);
      expect(model.upiTransactions, 11);
      expect(model.cardTransactions, 3);
    });

    test("ShiftSummaryModel correctly calculates cash drawer balance", () {
      final json = {
        "shiftDate": "2026-11-13",
        "openingFloat": 1000.0,
        "cashCollected": 4500.0,
        "cashOnHand": 5500.0,
        "billsIssued": 8,
      };

      final model = ShiftSummaryModel.fromJson(json);

      expect(model.openingFloat, 1000.0);
      expect(model.cashCollected, 4500.0);
      expect(model.cashOnHand, 5500.0);
      expect(model.billsIssued, 8);
      expect(model.cashOnHand, model.openingFloat + model.cashCollected);
    });

    test("SAdminDashboardModel correctly parses system health and KPI", () {
      final json = {
        "shop": {
          "companyId": 1,
          "companyName": "LitePOS Gourmet Cafe",
          "shopId": 1,
          "shopName": "Main Branch",
          "businessType": "Cafe",
          "currencyCode": "INR",
          "contactNumber": "+91 9876543210",
          "email": "contact@litepos.com",
        },
        "totalUsers": 3,
        "activeUsers": 3,
        "registeredDevices": 3,
        "offlineDevices": 1,
        "syncFailures": 0,
        "totalInvoicesAllTime": 24,
        "totalSalesAllTime": 15420.50,
        "appHealth": {
          "status": "Healthy",
          "databaseConnection": "Connected",
          "localDbStatus": "Ready",
          "pendingSyncRecords": 0,
          "serverTimeUtc": "2026-11-13T04:00:00Z",
        },
        "recentAuditActivities": [
          "Cashier Anand Kumar completed counter payment",
          "Admin opened shift register",
        ],
      };

      final model = SAdminDashboardModel.fromJson(json);

      expect(model.shop.companyName, "LitePOS Gourmet Cafe");
      expect(model.totalUsers, 3);
      expect(model.activeUsers, 3);
      expect(model.registeredDevices, 3);
      expect(model.appHealth.status, "Healthy");
      expect(model.recentAuditActivities.length, 2);
    });

    test("CashierDashboardModel correctly parses cashier KPIs", () {
      final json = {
        "cashierId": 3,
        "cashierName": "Anand Kumar",
        "todaySales": 5200.0,
        "todayInvoices": 9,
        "cashCollected": 3000.0,
        "upiCollected": 1500.0,
        "cardCollected": 700.0,
        "heldBillsCount": 1,
        "shiftSummary": {
          "shiftDate": "2026-11-13",
          "openingFloat": 1000.0,
          "cashCollected": 3000.0,
          "cashOnHand": 4000.0,
          "billsIssued": 9,
        },
        "recentTransactions": [
          {
            "invoiceId": 101,
            "invoiceNumber": "INV-20261113-0001",
            "customerName": "Karthik Raja",
            "cashierName": "Anand Kumar",
            "totalAmount": 450.0,
            "paymentMode": "Cash",
            "invoiceStatus": "Active",
            "createdAt": "2026-11-13T04:15:00Z",
          }
        ],
      };

      final model = CashierDashboardModel.fromJson(json);

      expect(model.cashierId, 3);
      expect(model.cashierName, "Anand Kumar");
      expect(model.todaySales, 5200.0);
      expect(model.heldBillsCount, 1);
      expect(model.recentTransactions.first.invoiceNumber, "INV-20261113-0001");
      expect(model.shiftSummary.cashOnHand, 4000.0);
    });
  });
}

