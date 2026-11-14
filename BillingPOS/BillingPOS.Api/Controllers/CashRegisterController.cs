using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/cash-register")]
[Authorize]
public class CashRegisterController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public CashRegisterController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    /// <summary>
    /// Opens the cash register session with an initial float.
    /// </summary>
    [HttpPost("open")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CashRegisterSessionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> OpenRegister([FromBody] OpenCashRegisterDto dto, CancellationToken cancellationToken)
    {
        var response = await _paymentService.OpenCashRegisterAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Closes the cash register session, records actual cash count, and calculates discrepancies.
    /// </summary>
    [HttpPost("close")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CashRegisterSessionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CloseRegister([FromBody] CloseCashRegisterDto dto, CancellationToken cancellationToken)
    {
        var response = await _paymentService.CloseCashRegisterAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }
}

