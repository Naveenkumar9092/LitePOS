using BillingPOS.Domain.Interfaces;

namespace BillingPOS.Domain.Entities;

public abstract class AuditableEntity<TKey> : BaseEntity<TKey>, IAuditableEntity
{
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public string? CreatedBy { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
    public string? UpdatedBy { get; set; }
    public bool IsActive { get; set; } = true;
}

public abstract class AuditableEntity : AuditableEntity<long>
{
}

