using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class Company : AuditableEntity<long>
{
    public string CompanyName { get; set; } = string.Empty;
    public string? LegalName { get; set; }
    public BusinessType BusinessType { get; set; } = BusinessType.Cafe;
    public string? GSTIN { get; set; }
    public string? PAN { get; set; }
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string? Website { get; set; }
    public string? LogoStorageKey { get; set; }

    // Navigation property - Only one shop supported in this system
    public virtual Shop? Shop { get; set; }
    public virtual ICollection<User> Users { get; set; } = new List<User>();
}

