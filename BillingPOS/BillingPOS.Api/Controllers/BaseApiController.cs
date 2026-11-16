using Asp.Versioning;
using BillingPOS.Application.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    protected IActionResult OkResponse<T>(T data, string message = "Operation completed successfully")
    {
        return Ok(ApiResponse<T>.SuccessResult(data, message));
    }

    protected IActionResult OkResponse(string message = "Operation completed successfully")
    {
        return Ok(ApiResponse.SuccessResult(message));
    }

    protected IActionResult CreatedResponse<T>(string uri, T data, string message = "Resource created successfully")
    {
        return Created(uri, ApiResponse<T>.SuccessResult(data, message));
    }

    protected IActionResult BadRequestResponse(string message, List<string>? errors = null)
    {
        return BadRequest(ApiResponse.FailureResult(message, errors));
    }

    protected IActionResult NotFoundResponse(string message = "Resource not found")
    {
        return NotFound(ApiResponse.FailureResult(message));
    }
}

