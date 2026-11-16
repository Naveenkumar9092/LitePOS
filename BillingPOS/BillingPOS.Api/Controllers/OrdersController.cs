using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/orders")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    /// <summary>
    /// Creates a new order (Counter Sale or Takeaway).
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderDto dto, CancellationToken cancellationToken)
    {
        var response = await _orderService.CreateOrderAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }

        return CreatedAtAction(nameof(GetOrderById), new { id = response.Data!.Id }, response);
    }

    /// <summary>
    /// Retrieves paginated orders with optional filters by status, type, dates, and search query.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PagedOrdersResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOrders(
        [FromQuery] OrderStatus? status,
        [FromQuery] OrderType? type,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var filter = new OrderFilterDto
        {
            Status = status,
            Type = type,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = search,
            Page = page,
            PageSize = pageSize
        };

        var response = await _orderService.GetOrdersAsync(filter, cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Retrieves order history (completed and cancelled orders).
    /// </summary>
    [HttpGet("history")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PagedOrdersResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOrderHistory(
        [FromQuery] OrderStatus? status,
        [FromQuery] OrderType? type,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var filter = new OrderFilterDto
        {
            Status = status,
            Type = type,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = search,
            Page = page,
            PageSize = pageSize
        };

        var response = await _orderService.GetOrderHistoryAsync(filter, cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Retrieves details of a specific order by ID.
    /// </summary>
    [HttpGet("{id:long}")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrderById(long id, CancellationToken cancellationToken)
    {
        var response = await _orderService.GetOrderByIdAsync(id, cancellationToken);
        if (!response.Success)
        {
            return NotFound(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Updates an order's status (e.g. New -> Confirmed -> Preparing -> Ready -> Completed).
    /// </summary>
    [HttpPut("{id:long}/status")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateOrderStatus(long id, [FromBody] UpdateOrderStatusDto dto, CancellationToken cancellationToken)
    {
        var response = await _orderService.UpdateOrderStatusAsync(id, dto, cancellationToken);
        if (!response.Success)
        {
            if (response.Message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(response);
            }
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Cancels an order with a mandatory cancellation reason.
    /// </summary>
    [HttpPost("{id:long}/cancel")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CancelOrder(long id, [FromBody] CancelOrderDto dto, CancellationToken cancellationToken)
    {
        var response = await _orderService.CancelOrderAsync(id, dto, cancellationToken);
        if (!response.Success)
        {
            if (response.Message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(response);
            }
            return BadRequest(response);
        }

        return Ok(response);
    }
}

