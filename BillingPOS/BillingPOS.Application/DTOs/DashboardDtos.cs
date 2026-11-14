namespace BillingPOS.Application.DTOs;

public record SAdminDashboardDto(
    ShopInfoDto ShopInfo,
    int TotalUsers,
    int ActiveUsers,
    int RegisteredDevices,
    int OfflineDevices,
    int SyncFailures,
    int TotalInvoices,
    decimal TotalSales,
    decimal TodaySales,
    int TodayInvoices,
    AppHealthDto AppHealth,
    List<LoginAuditLogDto> RecentAuditLogs
);

public record AdminDashboardDto(
    decimal TodaySales,
    int TodayInvoices,
    decimal CashSales,
    decimal UpiSales,
    decimal CardSales,
    int TotalCustomers,
    int CompletedOrders,
    int CancelledOrders,
    List<SalesGraphPointDto> DailySalesGraph,
    List<SalesGraphPointDto> MonthlySalesGraph,
    List<CashierSalesDto> CashierWiseSales,
    List<RecentTransactionDto> RecentInvoices
);

public record CashierDashboardDto(
    long CashierId,
    string CashierName,
    decimal TodaySales,
    int TodayInvoices,
    decimal CashCollected,
    decimal UpiCollected,
    decimal CardCollected,
    int HeldBillsCount,
    List<RecentTransactionDto> RecentTransactions,
    ShiftSummaryDto ShiftSummary
);

public record SalesSummaryDto(
    string Period,
    decimal TotalSales,
    int TotalInvoices,
    decimal AverageBillValue,
    decimal TotalTax,
    decimal TotalDiscount
);

public record PaymentSummaryDto(
    string Period,
    decimal TotalAmount,
    decimal CashAmount,
    decimal UpiAmount,
    decimal CardAmount,
    double CashPercent,
    double UpiPercent,
    double CardPercent
);

public record RecentTransactionDto(
    long InvoiceId,
    string InvoiceNumber,
    string CustomerName,
    string CashierName,
    decimal Amount,
    string PaymentMode,
    string PaymentStatus,
    string InvoiceStatus,
    DateTime InvoiceDateUtc
);

public record SalesGraphPointDto(
    string Label,
    decimal Amount,
    int Count
);

public record CashierSalesDto(
    long CashierId,
    string CashierName,
    int InvoiceCount,
    decimal TotalSales
);

public record ShiftSummaryDto(
    DateTime ShiftStartedAtUtc,
    decimal OpeningFloat,
    decimal TotalCollected,
    decimal CashOnHand,
    decimal UpiTotal,
    decimal CardTotal
);

public record ShopInfoDto(
    string CompanyName,
    string ShopName,
    string BusinessType,
    string? GSTIN,
    string ContactNumber,
    string City,
    string State
);

public record AppHealthDto(
    string Status,
    string Provider,
    string Uptime,
    DateTime ServerTimeUtc
);

