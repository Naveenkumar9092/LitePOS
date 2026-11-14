using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class Refund : BaseEntity<long>
{
    public Guid RefundGuid { get; set; } = Guid.NewGuid();
    public long InvoiceId { get; set; }
    public long? PaymentId { get; set; }
    public decimal Amount { get; set; }
    public PaymentMode PaymentMode { get; set; } = PaymentMode.Cash;
    public string Reason { get; set; } = string.Empty;
    public string AuthorizedBy { get; set; } = string.Empty;
    public string ProcessedBy { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation property
    public virtual Invoice? Invoice { get; set; }
}

