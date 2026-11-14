using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public class CompanySetupRequestDto
{
    // Company Information
    public string CompanyName { get; set; } = string.Empty;
    public string? LegalName { get; set; }
    public BusinessType BusinessType { get; set; } = BusinessType.Cafe;
    public string? GSTIN { get; set; }
    public string? PAN { get; set; }
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string? Website { get; set; }

    // Shop Information
    public string ShopName { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string Country { get; set; } = "India";
    public string ContactNumber { get; set; } = string.Empty;
    public string ShopEmail { get; set; } = string.Empty;
    public string TimeZone { get; set; } = "India Standard Time";
    public string CurrencyCode { get; set; } = "INR";
    public string? InvoiceHeader { get; set; }
    public string? InvoiceFooter { get; set; }
}

public class CompanyProfileDto
{
    public long CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? LegalName { get; set; }
    public BusinessType BusinessType { get; set; }
    public string BusinessTypeName => BusinessType.ToString();
    public string? GSTIN { get; set; }
    public string? PAN { get; set; }
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string? Website { get; set; }
    public string? LogoStorageKey { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }

    public ShopDto? Shop { get; set; }
}

public class ShopDto
{
    public long ShopId { get; set; }
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
    public bool IsActive { get; set; }
}

public class UpdateCompanyProfileDto
{
    public string CompanyName { get; set; } = string.Empty;
    public string? LegalName { get; set; }
    public BusinessType BusinessType { get; set; }
    public string? GSTIN { get; set; }
    public string? PAN { get; set; }
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string? Website { get; set; }
}

public class ShopConfigurationDto
{
    public long ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public BusinessType BusinessType { get; set; }
    public string BusinessTypeName => BusinessType.ToString();
    public string TimeZone { get; set; } = "India Standard Time";
    public string CurrencyCode { get; set; } = "INR";
    public string? InvoiceHeader { get; set; }
    public string? InvoiceFooter { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string ContactNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class UpdateShopConfigurationDto
{
    public string ShopName { get; set; } = string.Empty;
    public BusinessType BusinessType { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string ContactNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string TimeZone { get; set; } = "India Standard Time";
    public string CurrencyCode { get; set; } = "INR";
    public string? InvoiceHeader { get; set; }
    public string? InvoiceFooter { get; set; }
}

