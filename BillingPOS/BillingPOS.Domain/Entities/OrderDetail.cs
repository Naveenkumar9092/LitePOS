namespace BillingPOS.Domain.Entities;

public class OrderDetail : BaseEntity<long>
{
    public long OrderId { get; set; }
    public long ProductId { get; set; }
    public string ProductNameSnapshot { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxPercentage { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }

    // Navigation property
    public virtual Order Order { get; set; } = null!;
}

