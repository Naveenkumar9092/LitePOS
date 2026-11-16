using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/gst")]
[Authorize]
public class GstController : ControllerBase
{
    private readonly IGstService _gstService;

    public GstController(IGstService gstService)
    {
        _gstService = gstService;
    }

    /// <summary>
    /// Gets all configured GST tax rates.
    /// </summary>
    [HttpGet("taxes")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<TaxDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTaxes([FromQuery] bool? activeOnly, CancellationToken cancellationToken)
    {
        var taxes = await _gstService.GetTaxesAsync(activeOnly, cancellationToken);
        return Ok(ApiResponse<List<TaxDto>>.SuccessResult(taxes, "Taxes retrieved successfully."));
    }

    /// <summary>
    /// Creates a new tax slab.
    /// </summary>
    [HttpPost("taxes")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<TaxDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateTax([FromBody] CreateTaxDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var tax = await _gstService.CreateTaxAsync(dto, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<TaxDto>.SuccessResult(tax, "Tax created successfully."));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Updates an existing tax slab.
    /// </summary>
    [HttpPut("taxes/{id:long}")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<TaxDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateTax([FromRoute] long id, [FromBody] UpdateTaxDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var tax = await _gstService.UpdateTaxAsync(id, dto, cancellationToken);
            return Ok(ApiResponse<TaxDto>.SuccessResult(tax, "Tax updated successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Gets all configured HSN/SAC codes.
    /// </summary>
    [HttpGet("hsn")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<HsnSacDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHsnSacs([FromQuery] bool? activeOnly, CancellationToken cancellationToken)
    {
        var hsnList = await _gstService.GetHsnSacsAsync(activeOnly, cancellationToken);
        return Ok(ApiResponse<List<HsnSacDto>>.SuccessResult(hsnList, "HSN/SAC codes retrieved successfully."));
    }

    /// <summary>
    /// Adds or updates an HSN/SAC code.
    /// </summary>
    [HttpPost("hsn")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<HsnSacDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateOrUpdateHsnSac([FromBody] CreateHsnSacDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var hsn = await _gstService.CreateOrUpdateHsnSacAsync(dto, cancellationToken);
            return Ok(ApiResponse<HsnSacDto>.SuccessResult(hsn, "HSN/SAC code saved successfully."));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Gets current GST configuration and shop legal parameters.
    /// </summary>
    [HttpGet("config")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<GstConfigurationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetConfig(CancellationToken cancellationToken)
    {
        var config = await _gstService.GetGstConfigurationAsync(cancellationToken);
        return Ok(ApiResponse<GstConfigurationDto>.SuccessResult(config, "GST configuration retrieved successfully."));
    }

    /// <summary>
    /// Updates GST configuration and invoice layout parameters.
    /// </summary>
    [HttpPut("config")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<GstConfigurationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateConfig([FromBody] UpdateGstConfigurationDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var config = await _gstService.UpdateGstConfigurationAsync(dto, cancellationToken);
            return Ok(ApiResponse<GstConfigurationDto>.SuccessResult(config, "GST configuration updated successfully."));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Generates GST summary for GSTR-1 preparation (B2B, B2C, HSN breakdown, Credit Notes).
    /// </summary>
    [HttpGet("summary")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<GstSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary([FromQuery] DateTime? fromUtc, [FromQuery] DateTime? toUtc, CancellationToken cancellationToken)
    {
        var summary = await _gstService.GetGstSummaryAsync(fromUtc, toUtc, cancellationToken);
        return Ok(ApiResponse<GstSummaryDto>.SuccessResult(summary, "GST summary generated successfully."));
    }

    /// <summary>
    /// Issues a Credit Note or Debit Note linked to an existing invoice.
    /// </summary>
    [HttpPost("credit-notes")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CreditNoteDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreateCreditNote([FromBody] CreateCreditNoteDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var creditNote = await _gstService.CreateCreditNoteAsync(dto, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<CreditNoteDto>.SuccessResult(creditNote, $"{creditNote.NoteType} issued successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Lists all issued Credit and Debit Notes.
    /// </summary>
    [HttpGet("credit-notes")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<CreditNoteDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCreditNotes([FromQuery] long? invoiceId, [FromQuery] string? noteType, CancellationToken cancellationToken)
    {
        var list = await _gstService.GetCreditNotesAsync(invoiceId, noteType, cancellationToken);
        return Ok(ApiResponse<List<CreditNoteDto>>.SuccessResult(list, "Credit notes retrieved successfully."));
    }

    /// <summary>
    /// Gets specific Credit or Debit Note details by ID.
    /// </summary>
    [HttpGet("credit-notes/{id:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CreditNoteDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCreditNoteById([FromRoute] long id, CancellationToken cancellationToken)
    {
        try
        {
            var creditNote = await _gstService.GetCreditNoteByIdAsync(id, cancellationToken);
            return Ok(ApiResponse<CreditNoteDto>.SuccessResult(creditNote, "Credit note retrieved successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
    }
}
