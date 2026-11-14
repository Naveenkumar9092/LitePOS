using Asp.Versioning;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/dashboard")]
[Authorize]
public class DashboardController : BaseApiController
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("sadmin")]
    [Authorize(Roles = RoleConstants.SAdmin)]
    [ProducesResponseType(typeof(ApiResponse<SAdminDashboardDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSAdminDashboard(CancellationToken cancellationToken)
    {
        var result = await _dashboardService.GetSAdminDashboardAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet("admin")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<AdminDashboardDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAdminDashboard([FromQuery] DateTime? date, CancellationToken cancellationToken)
    {
        var result = await _dashboardService.GetAdminDashboardAsync(date, cancellationToken);
        return Ok(result);
    }

    [HttpGet("cashier")]
    [ProducesResponseType(typeof(ApiResponse<CashierDashboardDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCashierDashboard([FromQuery] long? cashierId, [FromQuery] DateTime? date, CancellationToken cancellationToken)
    {
        var result = await _dashboardService.GetCashierDashboardAsync(cashierId, date, cancellationToken);
        return Ok(result);
    }

    [HttpGet("sales-summary")]
    [ProducesResponseType(typeof(ApiResponse<SalesSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSalesSummary([FromQuery] string period = "today", CancellationToken cancellationToken = default)
    {
        var result = await _dashboardService.GetSalesSummaryAsync(period, cancellationToken);
        return Ok(result);
    }

    [HttpGet("payment-summary")]
    [ProducesResponseType(typeof(ApiResponse<PaymentSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPaymentSummary([FromQuery] string period = "today", CancellationToken cancellationToken = default)
    {
        var result = await _dashboardService.GetPaymentSummaryAsync(period, cancellationToken);
        return Ok(result);
    }

    [HttpGet("recent-transactions")]
    [ProducesResponseType(typeof(ApiResponse<List<RecentTransactionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRecentTransactions([FromQuery] int limit = 10, [FromQuery] long? cashierId = null, CancellationToken cancellationToken = default)
    {
        var result = await _dashboardService.GetRecentTransactionsAsync(limit, cashierId, cancellationToken);
        return Ok(result);
    }
}

