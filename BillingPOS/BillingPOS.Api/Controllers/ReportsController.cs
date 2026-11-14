using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/reports")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    /// <summary>
    /// Gets sales KPI summary for specified date range.
    /// </summary>
    [HttpGet("summary")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<SalesReportSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSalesSummary([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetSalesSummaryAsync(filter, cancellationToken);
        return Ok(ApiResponse<SalesReportSummaryDto>.SuccessResult(result, "Sales summary retrieved successfully."));
    }

    /// <summary>
    /// Gets daily sales trends for date range.
    /// </summary>
    [HttpGet("daily")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<DailySalesDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDailySalesReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetDailySalesReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<DailySalesDto>>.SuccessResult(result, "Daily sales report retrieved successfully."));
    }

    /// <summary>
    /// Gets itemized sales breakdown ranked by top revenue.
    /// </summary>
    [HttpGet("products")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductSalesReportDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProductSalesReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetProductSalesReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<ProductSalesReportDto>>.SuccessResult(result, "Product sales report retrieved successfully."));
    }

    /// <summary>
    /// Gets category sales contribution breakdown.
    /// </summary>
    [HttpGet("categories")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<CategorySalesReportDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategorySalesReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetCategorySalesReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<CategorySalesReportDto>>.SuccessResult(result, "Category sales report retrieved successfully."));
    }

    /// <summary>
    /// Gets cashier performance metrics and cash collected.
    /// </summary>
    [HttpGet("cashiers")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<List<CashierPerformanceReportDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCashierPerformanceReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetCashierPerformanceReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<CashierPerformanceReportDto>>.SuccessResult(result, "Cashier performance report retrieved successfully."));
    }

    /// <summary>
    /// Gets GST tax slab breakdown and HSN summary.
    /// </summary>
    [HttpGet("gst")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<GstSummaryReportDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetGstSummaryReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetGstSummaryReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<GstSummaryReportDto>.SuccessResult(result, "GST tax summary report retrieved successfully."));
    }

    /// <summary>
    /// Gets hourly sales volume to identify peak cafe/dessert hours.
    /// </summary>
    [HttpGet("hourly")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<HourlySalesDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHourlySalesReport([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetHourlySalesReportAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<HourlySalesDto>>.SuccessResult(result, "Hourly sales report retrieved successfully."));
    }

    /// <summary>
    /// Gets payment mode distribution (Cash, UPI, Card).
    /// </summary>
    [HttpGet("payments")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<PaymentModeBreakdownDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPaymentModeBreakdown([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _reportService.GetPaymentModeBreakdownAsync(filter, cancellationToken);
        return Ok(ApiResponse<List<PaymentModeBreakdownDto>>.SuccessResult(result, "Payment mode breakdown retrieved successfully."));
    }

    /// <summary>
    /// Exports invoice sales report as CSV.
    /// </summary>
    [HttpGet("export/csv")]
    [Authorize(Roles = "SAdmin,Admin")]
    public async Task<IActionResult> ExportSalesReportCsv([FromQuery] ReportDateRangeFilterDto filter, CancellationToken cancellationToken)
    {
        var bytes = await _reportService.ExportSalesReportCsvAsync(filter, cancellationToken);
        var filename = $"Sales_Report_{DateTime.UtcNow:yyyyMMdd_HHmmss}.csv";
        return File(bytes, "text/csv", filename);
    }
}
