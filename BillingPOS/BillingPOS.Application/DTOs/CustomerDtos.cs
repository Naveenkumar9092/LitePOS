namespace BillingPOS.Application.DTOs;

public record CustomerDto(
    long Id,
    Guid CustomerGuid,
    string CustomerName,
    string MobileNumber,
    string? WhatsAppNumber,
    string? Email,
    string? Address,
    string? GSTIN,
    bool EmailConsent,
    bool WhatsAppConsent,
    int TotalInvoicesCount,
    decimal TotalSpent,
    DateTime? LastVisitDateUtc,
    bool IsActive,
    DateTime CreatedAtUtc);

public record CustomerLookupDto(
    long Id,
    string CustomerName,
    string MobileNumber,
    string? GSTIN,
    string? Email,
    string? WhatsAppNumber);

public record CreateCustomerDto(
    string CustomerName,
    string MobileNumber,
    string? WhatsAppNumber = null,
    string? Email = null,
    string? Address = null,
    string? GSTIN = null,
    bool EmailConsent = false,
    bool WhatsAppConsent = false);

public record UpdateCustomerDto(
    string CustomerName,
    string MobileNumber,
    string? WhatsAppNumber = null,
    string? Email = null,
    string? Address = null,
    string? GSTIN = null,
    bool EmailConsent = false,
    bool WhatsAppConsent = false,
    bool IsActive = true);

public record CustomerFilterDto(
    string? Search = null,
    int PageNumber = 1,
    int PageSize = 20);

public record PagedCustomersResultDto(
    List<CustomerDto> Items,
    int TotalCount,
    int PageNumber,
    int PageSize,
    int TotalPages);

public record CustomerInvoiceItemDto(
    long InvoiceId,
    string InvoiceNumber,
    DateTime InvoiceDateUtc,
    decimal GrandTotal,
    string PaymentStatus,
    int TotalItems);

public record CustomerPurchaseHistoryDto(
    long CustomerId,
    string CustomerName,
    string MobileNumber,
    string? GSTIN,
    int TotalInvoices,
    decimal TotalSpent,
    DateTime? FirstVisitDateUtc,
    DateTime? LastVisitDateUtc,
    List<CustomerInvoiceItemDto> Invoices);

