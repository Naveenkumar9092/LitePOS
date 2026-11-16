using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IOrderService
{
    Task<ApiResponse<OrderDto>> CreateOrderAsync(CreateOrderDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PagedOrdersResultDto>> GetOrdersAsync(OrderFilterDto filter, CancellationToken cancellationToken = default);
    Task<ApiResponse<OrderDto>> GetOrderByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<ApiResponse<OrderDto>> UpdateOrderStatusAsync(long id, UpdateOrderStatusDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<OrderDto>> CancelOrderAsync(long id, CancelOrderDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PagedOrdersResultDto>> GetOrderHistoryAsync(OrderFilterDto filter, CancellationToken cancellationToken = default);
}

