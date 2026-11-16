namespace BillingPOS.Domain.Entities;

public class CreditNote : AuditableEntity<long>
{
    public Guid CreditNoteGuid { get; set; } = Guid.NewGuid();
    public string CreditNoteNumber { get; set; } = string.Empty;
    public long CompanyId { get; set; } = 1;
    public long ShopId { get; set; } = 1;
    public long InvoiceId { get; set; }
    public string InvoiceNumberSnapshot { get; set; } = string.Empty;
    public long? CustomerId { get; set; }
    public string? CustomerNameSnapshot { get; set; }
    public string? CustomerGstinSnapshot { get; set; }
    public DateTime CreditNoteDateUtc { get; set; } = DateTime.UtcNow;
    public string Reason { get; set; } = string.Empty;
    public string NoteType { get; set; } = "CreditNote"; // CreditNote or DebitNote
    public decimal TaxableAmount { get; set; }
    public decimal CgstAmount { get; set; }
    public decimal SgstAmount { get; set; }
    public decimal IgstAmount { get; set; }
    public decimal TotalTaxAmount { get; set; }
    public decimal GrandTotal { get; set; }
    public string Status { get; set; } = "Issued"; // Issued, Adjusted, Cancelled
    public bool IsDeleted { get; set; }

    public virtual ICollection<CreditNoteItem> Items { get; set; } = new List<CreditNoteItem>();
}

