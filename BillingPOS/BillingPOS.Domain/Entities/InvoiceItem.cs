namespace BillingPOS.Domain.Entities;

public class InvoiceItem : BaseEntity<long>
{
    public long InvoiceId { get; set; }
    public long ProductId { get; set; }
    public string ProductNameSnapshot { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxPercentage { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }

    // Navigation property
    public virtual Invoice Invoice { get; set; } = null!;
}

