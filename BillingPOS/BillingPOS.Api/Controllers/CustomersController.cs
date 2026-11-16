using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/customers")]
[Authorize]
public class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    /// <summary>
    /// Gets paged customer directory with optional search query.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PagedCustomersResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCustomers([FromQuery] CustomerFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _customerService.GetCustomersAsync(filter, cancellationToken);
        return Ok(ApiResponse<PagedCustomersResultDto>.SuccessResult(result, "Customers retrieved successfully."));
    }

    /// <summary>
    /// Quick lookup by mobile number or name for fast POS billing selection.
    /// </summary>
    [HttpGet("lookup")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<CustomerLookupDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> LookupCustomers([FromQuery] string query, CancellationToken cancellationToken)
    {
        var result = await _customerService.LookupCustomersAsync(query, cancellationToken);
        return Ok(ApiResponse<List<CustomerLookupDto>>.SuccessResult(result, "Customer lookup results."));
    }

    /// <summary>
    /// Gets customer profile by ID.
    /// </summary>
    [HttpGet("{id:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CustomerDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCustomerById([FromRoute] long id, CancellationToken cancellationToken)
    {
        try
        {
            var customer = await _customerService.GetCustomerByIdAsync(id, cancellationToken);
            return Ok(ApiResponse<CustomerDto>.SuccessResult(customer, "Customer profile retrieved."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
    }

    /// <summary>
    /// Creates a new customer profile.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CustomerDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var customer = await _customerService.CreateCustomerAsync(dto, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<CustomerDto>.SuccessResult(customer, "Customer created successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse.FailureResult(ex.Message));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Updates customer profile details.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<CustomerDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCustomer([FromRoute] long id, [FromBody] UpdateCustomerDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var customer = await _customerService.UpdateCustomerAsync(id, dto, cancellationToken);
            return Ok(ApiResponse<CustomerDto>.SuccessResult(customer, "Customer profile updated successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse.FailureResult(ex.Message));
        }
        catch (FluentValidation.ValidationException ex)
        {
            var errors = ex.Errors.Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse.FailureResult("Validation failed.", errors));
        }
    }

    /// <summary>
    /// Gets customer invoice purchase history and lifetime metrics.
    /// </summary>
    [HttpGet("{id:long}/history")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<CustomerPurchaseHistoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPurchaseHistory([FromRoute] long id, CancellationToken cancellationToken)
    {
        try
        {
            var history = await _customerService.GetCustomerPurchaseHistoryAsync(id, cancellationToken);
            return Ok(ApiResponse<CustomerPurchaseHistoryDto>.SuccessResult(history, "Customer purchase history retrieved."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse.FailureResult(ex.Message));
        }
    }
}

