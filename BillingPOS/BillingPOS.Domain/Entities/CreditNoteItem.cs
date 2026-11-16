namespace BillingPOS.Domain.Entities;

public class CreditNoteItem : BaseEntity<long>
{
    public long CreditNoteId { get; set; }
    public long ProductId { get; set; }
    public string ProductNameSnapshot { get; set; } = string.Empty;
    public string? HSNCodeSnapshot { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TaxPercentage { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }
    public string? Reason { get; set; }

    public virtual CreditNote CreditNote { get; set; } = null!;
}

