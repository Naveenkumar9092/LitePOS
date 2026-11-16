using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public class CreateOrderItemDto
{
    public long ProductId { get; set; }
    public string? ProductNameSnapshot { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxPercentage { get; set; }
}

public class CreateOrderDto
{
    public long? CustomerId { get; set; }
    public OrderType OrderType { get; set; } = OrderType.CounterSale;
    public decimal DiscountAmount { get; set; }
    public string? Notes { get; set; }
    public List<CreateOrderItemDto> Items { get; set; } = new();
}

public class OrderDetailDto
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public long ProductId { get; set; }
    public string ProductNameSnapshot { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxPercentage { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }
}

public class OrderDto
{
    public long Id { get; set; }
    public Guid OrderGuid { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public long? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public string? CustomerMobile { get; set; }
    public OrderType OrderType { get; set; }
    public string OrderTypeName => OrderType.ToString();
    public OrderStatus OrderStatus { get; set; }
    public string OrderStatusName => OrderStatus.ToString();
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal GrandTotal { get; set; }
    public string CashierUsername { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
    public string? CreatedBy { get; set; }
    public string? UpdatedBy { get; set; }
    public long? InvoiceId { get; set; }
    public string? InvoiceNumber { get; set; }
    public List<OrderDetailDto> Details { get; set; } = new();
}

public class UpdateOrderStatusDto
{
    public OrderStatus NewStatus { get; set; }
    public string? Notes { get; set; }
}

public class CancelOrderDto
{
    public string Reason { get; set; } = string.Empty;
}

public class OrderFilterDto
{
    public OrderStatus? Status { get; set; }
    public OrderType? Type { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? SearchTerm { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class PagedOrdersResultDto
{
    public List<OrderDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
}

