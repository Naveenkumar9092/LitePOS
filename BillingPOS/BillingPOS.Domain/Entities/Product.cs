namespace BillingPOS.Domain.Entities;

public class Product : AuditableEntity<long>
{
    public Guid ProductGuid { get; set; } = Guid.NewGuid();
    public long CompanyId { get; set; }
    public long CategoryId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ProductImageStorageKey { get; set; }
    public decimal SellingPrice { get; set; }
    public long? TaxId { get; set; }
    public decimal TaxPercentage { get; set; }
    public string? HSNCode { get; set; }
    public bool IsAvailable { get; set; } = true;

    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual Category Category { get; set; } = null!;
}
