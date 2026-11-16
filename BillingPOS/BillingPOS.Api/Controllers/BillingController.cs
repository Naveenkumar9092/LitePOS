using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/billing")]
[Authorize]
public class BillingController : ControllerBase
{
    private readonly IBillingService _billingService;

    public BillingController(IBillingService billingService)
    {
        _billingService = billingService;
    }

    /// <summary>
    /// Creates a new sales invoice.
    /// </summary>
    [HttpPost("create")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateInvoice([FromBody] CreateInvoiceDto dto, CancellationToken cancellationToken)
    {
        var response = await _billingService.CreateInvoiceAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return CreatedAtAction(nameof(GetInvoiceById), new { id = response.Data!.InvoiceId }, response);
    }

    /// <summary>
    /// Gets paginated invoices with optional status, search, and date range filters.
    /// </summary>
    [HttpGet("invoices")]
    [ProducesResponseType(typeof(ApiResponse<PagedInvoicesResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetInvoices(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] InvoiceStatus? status = null,
        [FromQuery] string? search = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        CancellationToken cancellationToken = default)
    {
        var response = await _billingService.GetInvoicesAsync(pageNumber, pageSize, status, search, fromDate, toDate, cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Gets invoice details by ID.
    /// </summary>
    [HttpGet("invoices/{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetInvoiceById(long id, CancellationToken cancellationToken)
    {
        var response = await _billingService.GetInvoiceByIdAsync(id, cancellationToken);
        if (!response.Success)
        {
            return NotFound(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Places an in-progress bill on hold.
    /// </summary>
    [HttpPost("hold")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> HoldBill([FromBody] HoldBillDto dto, CancellationToken cancellationToken)
    {
        var response = await _billingService.HoldBillAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Gets all currently held bills.
    /// </summary>
    [HttpGet("held")]
    [ProducesResponseType(typeof(ApiResponse<List<InvoiceDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHeldBills(CancellationToken cancellationToken)
    {
        var response = await _billingService.GetHeldBillsAsync(cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Retrieves a held bill to resume billing.
    /// </summary>
    [HttpPost("resume/{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResumeBill(long id, CancellationToken cancellationToken)
    {
        var response = await _billingService.ResumeBillAsync(id, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Cancels an existing bill or invoice.
    /// </summary>
    [HttpPost("cancel/{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CancelBill(long id, [FromBody] CancelBillDto dto, CancellationToken cancellationToken)
    {
        var response = await _billingService.CancelBillAsync(id, dto.Reason, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Retrieves invoice data for thermal reprint.
    /// </summary>
    [HttpPost("reprint/{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ReprintBill(long id, CancellationToken cancellationToken)
    {
        var response = await _billingService.ReprintBillAsync(id, cancellationToken);
        if (!response.Success)
        {
            return NotFound(response);
        }

        return Ok(response);
    }
}

