namespace BillingPOS.Domain.Entities;

public class Tax : AuditableEntity<long>
{
    public long CompanyId { get; set; } = 1;
    public string TaxName { get; set; } = string.Empty;
    public decimal RatePercentage { get; set; }
    public decimal CgstPercentage { get; set; }
    public decimal SgstPercentage { get; set; }
    public decimal IgstPercentage { get; set; }
    public bool IsDefault { get; set; }
    public bool IsTaxInclusiveDefault { get; set; } = true;
    public bool IsDeleted { get; set; }
}

