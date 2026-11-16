import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/reports/models/report_models.dart";

void main() {
  group("Report Models Tests", () {
    test("SalesReportSummaryModel deserializes JSON correctly", () {
      final json = {
        "fromDateUtc": "2026-11-13T00:00:00Z",
        "toDateUtc": "2026-11-13T23:59:59Z",
        "totalInvoices": 10,
        "totalActiveInvoices": 9,
        "totalCancelledInvoices": 1,
        "grossSales": 5000.0,
        "totalDiscount": 200.0,
        "netSales": 4800.0,
        "totalTax": 240.0,
        "grandTotalSales": 5040.0,
        "totalRefunds": 100.0,
        "netRevenue": 4940.0,
        "totalCashCollected": 3000.0,
        "totalUpiCollected": 2040.0,
        "totalCardCollected": 0.0,
        "totalDueOutstanding": 0.0,
        "averageOrderValue": 560.0,
      };

      final model = SalesReportSummaryModel.fromJson(json);

      expect(model.totalInvoices, 10);
      expect(model.totalActiveInvoices, 9);
      expect(model.totalCancelledInvoices, 1);
      expect(model.grossSales, 5000.0);
      expect(model.totalDiscount, 200.0);
      expect(model.netSales, 4800.0);
      expect(model.totalTax, 240.0);
      expect(model.grandTotalSales, 5040.0);
      expect(model.netRevenue, 4940.0);
      expect(model.totalCashCollected, 3000.0);
      expect(model.totalUpiCollected, 2040.0);
      expect(model.averageOrderValue, 560.0);
    });

    test("DailySalesModel parses JSON correctly", () {
      final json = {
        "date": "2026-11-13T00:00:00Z",
        "invoiceCount": 5,
        "grossSales": 2500.0,
        "discountAmount": 100.0,
        "taxAmount": 120.0,
        "netSales": 2520.0,
        "cashAmount": 1500.0,
        "upiAmount": 1020.0,
        "cardAmount": 0.0,
      };

      final model = DailySalesModel.fromJson(json);

      expect(model.invoiceCount, 5);
      expect(model.grossSales, 2500.0);
      expect(model.discountAmount, 100.0);
      expect(model.taxAmount, 120.0);
      expect(model.netSales, 2520.0);
      expect(model.cashAmount, 1500.0);
      expect(model.upiAmount, 1020.0);
    });

    test("ProductSalesReportModel and CategorySalesReportModel parse JSON", () {
      final prodJson = {
        "productId": 1,
        "productName": "Espresso Coffee",
        "categoryName": "Beverages",
        "quantitySold": 12,
        "totalRevenue": 1200.0,
        "totalTax": 60.0,
        "percentageOfSales": 45.5,
      };

      final prodModel = ProductSalesReportModel.fromJson(prodJson);
      expect(prodModel.productId, 1);
      expect(prodModel.productName, "Espresso Coffee");
      expect(prodModel.categoryName, "Beverages");
      expect(prodModel.quantitySold, 12);
      expect(prodModel.totalRevenue, 1200.0);
      expect(prodModel.percentageOfSales, 45.5);

      final catJson = {
        "categoryId": 1,
        "categoryName": "Beverages",
        "totalQuantitySold": 25,
        "totalRevenue": 2500.0,
        "percentageOfSales": 60.0,
      };

      final catModel = CategorySalesReportModel.fromJson(catJson);
      expect(catModel.categoryId, 1);
      expect(catModel.categoryName, "Beverages");
      expect(catModel.totalQuantitySold, 25);
      expect(catModel.totalRevenue, 2500.0);
      expect(catModel.percentageOfSales, 60.0);
    });

    test("CashierPerformanceReportModel parses JSON", () {
      final json = {
        "cashierId": 2,
        "cashierName": "Suresh Raina",
        "username": "cashier",
        "invoicesCount": 8,
        "totalSales": 3200.0,
        "cashCollected": 2000.0,
        "digitalCollected": 1200.0,
        "refundsHandled": 50.0,
      };

      final model = CashierPerformanceReportModel.fromJson(json);
      expect(model.cashierId, 2);
      expect(model.cashierName, "Suresh Raina");
      expect(model.invoicesCount, 8);
      expect(model.totalSales, 3200.0);
      expect(model.cashCollected, 2000.0);
      expect(model.digitalCollected, 1200.0);
      expect(model.refundsHandled, 50.0);
    });

    test("GstSummaryReportModel parses slabs and HSN JSON", () {
      final json = {
        "slabs": [
          {
            "taxRate": 5.0,
            "taxableAmount": 1000.0,
            "cgstAmount": 25.0,
            "sgstAmount": 25.0,
            "totalTax": 50.0,
          },
          {
            "taxRate": 18.0,
            "taxableAmount": 2000.0,
            "cgstAmount": 180.0,
            "sgstAmount": 180.0,
            "totalTax": 360.0,
          }
        ],
        "totalTaxableAmount": 3000.0,
        "totalCgst": 205.0,
        "totalSgst": 205.0,
        "totalGst": 410.0,
        "hsnSummary": [
          {
            "hsnCode": "996331",
            "description": "Restaurant food",
            "totalQuantity": 15,
            "taxableAmount": 3000.0,
            "totalTax": 410.0,
            "totalValue": 3410.0,
          }
        ],
      };

      final model = GstSummaryReportModel.fromJson(json);
      expect(model.slabs.length, 2);
      expect(model.totalTaxableAmount, 3000.0);
      expect(model.totalGst, 410.0);
      expect(model.hsnSummary.length, 1);
      expect(model.hsnSummary.first.hsnCode, "996331");
    });

    test("ReportFilterModel quick filters construct valid dates", () {
      final todayFilter = ReportFilterModel.today();
      expect(todayFilter.rangeType, ReportDateRangeType.today);
      expect(todayFilter.fromDateUtc.hour, 0);
      expect(todayFilter.toDateUtc.hour, 23);

      final yestFilter = ReportFilterModel.yesterday();
      expect(yestFilter.rangeType, ReportDateRangeType.yesterday);

      final weekFilter = ReportFilterModel.thisWeek();
      expect(weekFilter.rangeType, ReportDateRangeType.thisWeek);

      final monthFilter = ReportFilterModel.thisMonth();
      expect(monthFilter.rangeType, ReportDateRangeType.thisMonth);
      expect(monthFilter.fromDateUtc.day, 1);

      final params = todayFilter.toQueryParams();
      expect(params.containsKey("fromDateUtc"), true);
      expect(params.containsKey("toDateUtc"), true);
    });
  });
}

