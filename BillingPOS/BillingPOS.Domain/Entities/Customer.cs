namespace BillingPOS.Domain.Entities;

public class Customer : AuditableEntity<long>
{
    public Guid CustomerGuid { get; set; } = Guid.NewGuid();
    public string CustomerName { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string? WhatsAppNumber { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? GSTIN { get; set; }
    public bool EmailConsent { get; set; }
    public bool WhatsAppConsent { get; set; }

    // Navigation properties
    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
    public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
}

