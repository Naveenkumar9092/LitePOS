using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/payments")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    /// <summary>
    /// Processes a single payment (Cash, UPI, Card) for an invoice.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PaymentTransactionDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ProcessPayment([FromBody] ProcessPaymentDto dto, CancellationToken cancellationToken)
    {
        var response = await _paymentService.ProcessPaymentAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return CreatedAtAction(nameof(GetPaymentById), new { id = response.Data!.Id }, response);
    }

    /// <summary>
    /// Processes a split payment across multiple payment modes for an invoice.
    /// </summary>
    [HttpPost("split")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<PaymentTransactionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ProcessSplitPayment([FromBody] ProcessSplitPaymentDto dto, CancellationToken cancellationToken)
    {
        var response = await _paymentService.ProcessSplitPaymentAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Issues a refund for an invoice or specific payment.
    /// </summary>
    [HttpPost("refund")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PaymentTransactionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ProcessRefund([FromBody] ProcessRefundDto dto, CancellationToken cancellationToken)
    {
        var response = await _paymentService.ProcessRefundAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Retrieves payment history with filters.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PagedPaymentsResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPayments(
        [FromQuery] long? invoiceId,
        [FromQuery] PaymentMode? paymentMode,
        [FromQuery] PaymentStatus? paymentStatus,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var filter = new PaymentFilterDto
        {
            InvoiceId = invoiceId,
            PaymentMode = paymentMode,
            PaymentStatus = paymentStatus,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = search,
            Page = page,
            PageSize = pageSize
        };

        var response = await _paymentService.GetPaymentsAsync(filter, cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Retrieves details of a specific payment by ID.
    /// </summary>
    [HttpGet("{id:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PaymentTransactionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPaymentById(long id, CancellationToken cancellationToken)
    {
        var response = await _paymentService.GetPaymentByIdAsync(id, cancellationToken);
        if (!response.Success)
        {
            return NotFound(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Retrieves end-of-day / shift payment reconciliation.
    /// </summary>
    [HttpGet("reconciliation")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PaymentReconciliationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetReconciliation([FromQuery] DateTime? date, CancellationToken cancellationToken)
    {
        var response = await _paymentService.GetPaymentReconciliationAsync(date, cancellationToken);
        return Ok(response);
    }
}

