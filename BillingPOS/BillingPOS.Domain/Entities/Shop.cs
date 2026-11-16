namespace BillingPOS.Domain.Entities;

public class Shop : AuditableEntity<long>
{
    public long CompanyId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string Country { get; set; } = "India";
    public string ContactNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string TimeZone { get; set; } = "India Standard Time";
    public string CurrencyCode { get; set; } = "INR";
    public string? InvoiceHeader { get; set; }
    public string? InvoiceFooter { get; set; }

    // Navigation property
    public virtual Company Company { get; set; } = null!;
    public virtual ICollection<User> Users { get; set; } = new List<User>();
}

