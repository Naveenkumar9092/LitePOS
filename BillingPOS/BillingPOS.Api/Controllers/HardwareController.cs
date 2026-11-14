using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/hardware")]
[Authorize]
public class HardwareController : ControllerBase
{
    private readonly IHardwareService _hardwareService;

    public HardwareController(IHardwareService hardwareService)
    {
        _hardwareService = hardwareService;
    }

    /// <summary>
    /// Gets all configured thermal receipt printers.
    /// </summary>
    [HttpGet("printers")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<PrinterConfigurationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPrinters(CancellationToken cancellationToken)
    {
        var result = await _hardwareService.GetPrintersAsync(cancellationToken);
        return Ok(ApiResponse<List<PrinterConfigurationDto>>.SuccessResult(result, "Printers retrieved successfully."));
    }

    /// <summary>
    /// Gets printer configuration by ID.
    /// </summary>
    [HttpGet("printers/{id:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PrinterConfigurationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPrinterById([FromRoute] long id, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.GetPrinterByIdAsync(id, cancellationToken);
        if (result == null)
            return NotFound(ApiResponse.FailureResult($"Printer #{id} not found."));

        return Ok(ApiResponse<PrinterConfigurationDto>.SuccessResult(result, "Printer configuration retrieved."));
    }

    /// <summary>
    /// Gets default receipt printer configuration.
    /// </summary>
    [HttpGet("printers/default")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PrinterConfigurationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDefaultPrinter(CancellationToken cancellationToken)
    {
        var result = await _hardwareService.GetDefaultPrinterAsync(cancellationToken);
        return Ok(ApiResponse<PrinterConfigurationDto>.SuccessResult(result, "Default printer retrieved."));
    }

    /// <summary>
    /// Creates a new thermal printer configuration.
    /// </summary>
    [HttpPost("printers")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<PrinterConfigurationDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreatePrinter([FromBody] CreatePrinterConfigurationDto dto, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.CreatePrinterAsync(dto, cancellationToken);
        return CreatedAtAction(nameof(GetPrinterById), new { id = result.Id }, ApiResponse<PrinterConfigurationDto>.SuccessResult(result, "Printer created successfully."));
    }

    /// <summary>
    /// Updates an existing thermal printer configuration.
    /// </summary>
    [HttpPut("printers/{id:long}")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<PrinterConfigurationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdatePrinter([FromRoute] long id, [FromBody] UpdatePrinterConfigurationDto dto, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.UpdatePrinterAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<PrinterConfigurationDto>.SuccessResult(result, "Printer updated successfully."));
    }

    /// <summary>
    /// Deactivates a thermal printer configuration.
    /// </summary>
    [HttpDelete("printers/{id:long}")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeletePrinter([FromRoute] long id, CancellationToken cancellationToken)
    {
        var success = await _hardwareService.DeletePrinterAsync(id, cancellationToken);
        if (!success)
            return NotFound(ApiResponse.FailureResult($"Printer #{id} not found."));

        return Ok(ApiResponse.SuccessResult("Printer deleted successfully."));
    }

    /// <summary>
    /// Sets a printer as the default receipt printer.
    /// </summary>
    [HttpPost("printers/{id:long}/set-default")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<PrinterConfigurationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetDefaultPrinter([FromRoute] long id, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.SetDefaultPrinterAsync(id, cancellationToken);
        return Ok(ApiResponse<PrinterConfigurationDto>.SuccessResult(result, "Default printer updated."));
    }

    /// <summary>
    /// Generates ESC/POS test receipt bytes with alignment and paper cut.
    /// </summary>
    [HttpPost("test-print")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<TestPrintResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> TestPrint([FromQuery] long? printerId, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.GenerateTestPrintAsync(printerId, cancellationToken);
        return Ok(ApiResponse<TestPrintResultDto>.SuccessResult(result, "Test print ESC/POS bytes generated."));
    }

    /// <summary>
    /// Generates ESC/POS cash drawer kick command sequence.
    /// </summary>
    [HttpPost("open-drawer")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CashDrawerCommandDto>), StatusCodes.Status200OK)]
    public IActionResult OpenCashDrawer()
    {
        var result = _hardwareService.GenerateOpenCashDrawerCommand();
        return Ok(ApiResponse<CashDrawerCommandDto>.SuccessResult(result, "Cash drawer kick command generated."));
    }

    /// <summary>
    /// Generates ESC/POS thermal receipt bytes for an invoice.
    /// </summary>
    [HttpGet("receipt/{invoiceId:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<ReceiptPrintResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetInvoiceReceipt([FromRoute] long invoiceId, [FromQuery] long? printerId, CancellationToken cancellationToken)
    {
        var result = await _hardwareService.GenerateInvoiceReceiptEscPosAsync(invoiceId, printerId, cancellationToken);
        return Ok(ApiResponse<ReceiptPrintResultDto>.SuccessResult(result, "Receipt ESC/POS bytes generated."));
    }
}
