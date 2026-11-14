namespace BillingPOS.Domain.Entities;

public class HsnSac : AuditableEntity<long>
{
    public long CompanyId { get; set; } = 1;
    public string Code { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Type { get; set; } = "HSN"; // HSN or SAC
    public decimal DefaultGstRate { get; set; } = 5.0m;
    public bool IsDeleted { get; set; }
}

