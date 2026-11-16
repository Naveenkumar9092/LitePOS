using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class Invoice : AuditableEntity<long>
{
    public Guid InvoiceGuid { get; set; } = Guid.NewGuid();
    public string InvoiceNumber { get; set; } = string.Empty;
    public long CompanyId { get; set; }
    public long ShopId { get; set; }
    public long? OrderId { get; set; }
    public long? CustomerId { get; set; }
    public long CashierId { get; set; }
    public string DeviceId { get; set; } = "POS-TERMINAL-01";
    public DateTime InvoiceDateUtc { get; set; } = DateTime.UtcNow;

    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxableAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal GrandTotal { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal BalanceAmount { get; set; }

    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Paid;
    public InvoiceStatus InvoiceStatus { get; set; } = InvoiceStatus.Active;
    public SyncStatus SyncStatus { get; set; } = SyncStatus.Synced;

    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual Shop Shop { get; set; } = null!;
    public virtual Customer? Customer { get; set; }
    public virtual User Cashier { get; set; } = null!;
    public virtual Order? Order { get; set; }
    public virtual ICollection<InvoiceItem> Items { get; set; } = new List<InvoiceItem>();
    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
}

