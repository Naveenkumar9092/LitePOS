namespace BillingPOS.Domain.Entities;

public class GstConfiguration : AuditableEntity<long>
{
    public long CompanyId { get; set; } = 1;
    public long ShopId { get; set; } = 1;
    public string GSTIN { get; set; } = "33AAAAA0000A1Z5";
    public string LegalName { get; set; } = "LitePOS Tech Pvt Ltd";
    public string TradeName { get; set; } = "LitePOS Cafe & Desserts";
    public string StateName { get; set; } = "Tamil Nadu";
    public string StateCode { get; set; } = "33";
    public bool IsCompositionScheme { get; set; }
    public bool DefaultPricingIsTaxInclusive { get; set; } = true;
    public string? InvoiceTermsAndConditions { get; set; }
    public string? InvoiceHeader { get; set; }
    public string? InvoiceFooter { get; set; }
    public bool ShowHsnSummaryOnReceipt { get; set; } = true;
    public bool ShowTaxBreakupOnReceipt { get; set; } = true;
    public bool IsDeleted { get; set; }
}

