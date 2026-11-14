namespace BillingPOS.Domain.Entities;

public class Category : AuditableEntity<long>
{
    public Guid CategoryGuid { get; set; } = Guid.NewGuid();
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CategoryImageStorageKey { get; set; }
    public int DisplayOrder { get; set; }

    // Navigation property
    public virtual ICollection<Product> Products { get; set; } = new List<Product>();
}
