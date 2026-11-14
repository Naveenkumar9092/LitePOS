using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class Order : AuditableEntity<long>
{
    public Guid OrderGuid { get; set; } = Guid.NewGuid();
    public string OrderNumber { get; set; } = string.Empty;
    public long? CustomerId { get; set; }
    public OrderType OrderType { get; set; } = OrderType.CounterSale;
    public OrderStatus OrderStatus { get; set; } = OrderStatus.New;
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal GrandTotal { get; set; }
    public string CashierUsername { get; set; } = string.Empty;

    // Navigation properties
    public virtual Customer? Customer { get; set; }
    public virtual ICollection<OrderDetail> Details { get; set; } = new List<OrderDetail>();
    public virtual Invoice? Invoice { get; set; }
}

