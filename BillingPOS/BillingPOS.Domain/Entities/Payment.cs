using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class Payment : BaseEntity<long>
{
    public Guid PaymentGuid { get; set; } = Guid.NewGuid();
    public long InvoiceId { get; set; }
    public PaymentMode PaymentMode { get; set; } = PaymentMode.Cash;
    public string PaymentModeName { get; set; } = "Cash";
    public decimal Amount { get; set; }
    public string? TransactionReference { get; set; }
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Paid;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation property
    public virtual Invoice Invoice { get; set; } = null!;
}

