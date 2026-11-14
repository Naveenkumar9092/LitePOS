namespace BillingPOS.Application.DTOs;

public record TaxDto(
    long Id,
    string TaxName,
    decimal RatePercentage,
    decimal CgstPercentage,
    decimal SgstPercentage,
    decimal IgstPercentage,
    bool IsActive,
    bool IsDefault,
    bool IsTaxInclusiveDefault);

public record CreateTaxDto(
    string TaxName,
    decimal RatePercentage,
    bool IsDefault = false,
    bool IsTaxInclusiveDefault = true);

public record UpdateTaxDto(
    string TaxName,
    decimal RatePercentage,
    bool IsActive = true,
    bool IsDefault = false,
    bool IsTaxInclusiveDefault = true);

public record HsnSacDto(
    long Id,
    string Code,
    string Description,
    string Type,
    decimal DefaultGstRate,
    bool IsActive);

public record CreateHsnSacDto(
    string Code,
    string Description,
    string Type,
    decimal DefaultGstRate,
    bool IsActive = true);

public record GstConfigurationDto(
    long Id,
    string GSTIN,
    string LegalName,
    string TradeName,
    string StateName,
    string StateCode,
    bool IsCompositionScheme,
    bool DefaultPricingIsTaxInclusive,
    string? InvoiceTermsAndConditions,
    string? InvoiceHeader,
    string? InvoiceFooter,
    bool ShowHsnSummaryOnReceipt,
    bool ShowTaxBreakupOnReceipt);

public record UpdateGstConfigurationDto(
    string GSTIN,
    string LegalName,
    string TradeName,
    string StateName,
    string StateCode,
    bool IsCompositionScheme,
    bool DefaultPricingIsTaxInclusive,
    string? InvoiceTermsAndConditions,
    string? InvoiceHeader,
    string? InvoiceFooter,
    bool ShowHsnSummaryOnReceipt,
    bool ShowTaxBreakupOnReceipt);

public record CreateCreditNoteItemDto(
    long ProductId,
    int Quantity,
    decimal? UnitPrice = null,
    string? Reason = null);

public record CreateCreditNoteDto(
    long InvoiceId,
    string Reason,
    string NoteType = "CreditNote",
    List<CreateCreditNoteItemDto>? Items = null);

public record CreditNoteItemDto(
    long ProductId,
    string ProductName,
    string? HsnCode,
    int Quantity,
    decimal UnitPrice,
    decimal TaxPercentage,
    decimal TaxAmount,
    decimal LineTotal,
    string? Reason);

public record CreditNoteDto(
    long Id,
    Guid CreditNoteGuid,
    string CreditNoteNumber,
    long InvoiceId,
    string InvoiceNumber,
    long? CustomerId,
    string? CustomerName,
    string? CustomerGstin,
    DateTime CreditNoteDateUtc,
    string Reason,
    string NoteType,
    decimal TaxableAmount,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal IgstAmount,
    decimal TotalTaxAmount,
    decimal GrandTotal,
    string Status,
    List<CreditNoteItemDto> Items);

public record B2cSummaryDto(
    int TotalInvoices,
    decimal TaxableValue,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal IgstAmount,
    decimal TotalTax,
    decimal GrandTotal);

public record B2bInvoiceSummaryDto(
    long InvoiceId,
    string InvoiceNumber,
    DateTime InvoiceDateUtc,
    string CustomerName,
    string CustomerGstin,
    decimal TaxableValue,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal IgstAmount,
    decimal TotalTax,
    decimal GrandTotal);

public record B2bSummaryDto(
    int TotalInvoices,
    decimal TaxableValue,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal IgstAmount,
    decimal TotalTax,
    decimal GrandTotal,
    List<B2bInvoiceSummaryDto> Invoices);

public record HsnSummaryItemDto(
    string HsnCode,
    string Description,
    int TotalQuantity,
    decimal TaxableValue,
    decimal CgstAmount,
    decimal SgstAmount,
    decimal IgstAmount,
    decimal TotalTax);

public record CreditNotesSummaryDto(
    int TotalCount,
    decimal TotalTaxableReduced,
    decimal TotalTaxReduced,
    decimal NetSalesLiability);

public record GstSummaryDto(
    DateTime FromUtc,
    DateTime ToUtc,
    string CompanyGstin,
    string LegalName,
    string StateCode,
    B2cSummaryDto B2cSummary,
    B2bSummaryDto B2bSummary,
    List<HsnSummaryItemDto> HsnSummary,
    CreditNotesSummaryDto CreditNotesSummary);

