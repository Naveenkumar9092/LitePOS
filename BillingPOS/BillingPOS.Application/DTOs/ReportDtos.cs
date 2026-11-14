using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public record ReportDateRangeFilterDto(
    DateTime? FromDateUtc = null,
    DateTime? ToDateUtc = null,
    long? CashierId = null,
    long? CategoryId = null,
    PaymentMode? PaymentMode = null);

public record SalesReportSummaryDto(
    DateTime FromDateUtc,
    DateTime ToDateUtc,
    int TotalInvoices,
    int TotalActiveInvoices,
    int TotalCancelledInvoices,
    decimal GrossSales,
    decimal TotalDiscount,
    decimal NetSales,
    decimal TotalTax,
    decimal GrandTotalSales,
    decimal TotalRefunds,
    decimal NetRevenue,
    decimal TotalCashCollected,
    decimal TotalUpiCollected,
    decimal TotalCardCollected,
    decimal TotalDueOutstanding,
    decimal AverageOrderValue);

public record DailySalesDto(
    DateTime Date,
    int InvoiceCount,
    decimal GrossSales,
    decimal DiscountAmount,
    decimal TaxAmount,
    decimal NetSales,
    decimal CashAmount,
    decimal UpiAmount,
    decimal CardAmount);

public record ProductSalesReportDto(
    long ProductId,
    string ProductName,
    string CategoryName,
    int QuantitySold,
    decimal TotalRevenue,
    decimal TotalTax,
    decimal PercentageOfSales);

public record CategorySalesReportDto(
    long CategoryId,
    string CategoryName,
    int TotalQuantitySold,
    decimal TotalRevenue,
    decimal PercentageOfSales);

public record CashierPerformanceReportDto(
    long CashierId,
    string CashierName,
    string Username,
    int InvoicesCount,
    decimal TotalSales,
    decimal CashCollected,
    decimal DigitalCollected,
    decimal RefundsHandled);

public record GstSlabSummaryDto(
    decimal TaxRate,
    decimal TaxableAmount,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal TotalTax);

public record HsnSalesSummaryDto(
    string HsnCode,
    string Description,
    int TotalQuantity,
    decimal TaxableAmount,
    decimal TotalTax,
    decimal TotalValue);

public record GstSummaryReportDto(
    List<GstSlabSummaryDto> Slabs,
    decimal TotalTaxableAmount,
    decimal TotalCgst,
    decimal TotalSgst,
    decimal TotalGst,
    List<HsnSalesSummaryDto> HsnSummary);

public record HourlySalesDto(
    int Hour,
    string TimeSlot,
    int OrderCount,
    decimal TotalSales);

public record PaymentModeBreakdownDto(
    string PaymentMode,
    int TransactionCount,
    decimal TotalAmount,
    decimal Percentage);
