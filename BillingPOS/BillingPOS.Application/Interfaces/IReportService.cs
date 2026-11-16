using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IReportService
{
    Task<SalesReportSummaryDto> GetSalesSummaryAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<DailySalesDto>> GetDailySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<ProductSalesReportDto>> GetProductSalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<CategorySalesReportDto>> GetCategorySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<CashierPerformanceReportDto>> GetCashierPerformanceReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<GstSummaryReportDto> GetGstSummaryReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<HourlySalesDto>> GetHourlySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<List<PaymentModeBreakdownDto>> GetPaymentModeBreakdownAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
    Task<byte[]> ExportSalesReportCsvAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default);
}
