using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public record RegisterDeviceDto(
    string DeviceId,
    string DeviceName,
    string AppVersion = "1.0.0",
    bool IsOnline = true);

public record DeviceStatusDto(
    string DeviceId,
    string DeviceName,
    string AppVersion,
    bool IsOnline,
    DateTime? LastSyncTimeUtc,
    int SyncFailuresCount,
    DateTime RegisteredAtUtc);

public record SyncCustomerPushDto(
    Guid CustomerGuid,
    string CustomerName,
    string MobileNumber,
    string? WhatsAppNumber = null,
    string? Email = null,
    string? Address = null,
    string? GSTIN = null,
    bool EmailConsent = false,
    bool WhatsAppConsent = false,
    DateTime? CreatedAtUtc = null);

public record SyncInvoiceItemPushDto(
    long ProductId,
    string ProductNameSnapshot,
    decimal UnitPrice,
    int Quantity,
    decimal DiscountAmount,
    decimal TaxPercentage,
    decimal TaxAmount,
    decimal LineTotal);

public record SyncPaymentPushDto(
    Guid PaymentGuid,
    PaymentMode PaymentMode,
    decimal Amount,
    string? TransactionReference,
    PaymentStatus PaymentStatus,
    DateTime CreatedAtUtc);

public record SyncInvoicePushDto(
    Guid InvoiceGuid,
    string InvoiceNumber,
    long? CustomerId,
    Guid? CustomerGuid,
    long CashierId,
    DateTime InvoiceDateUtc,
    decimal SubTotal,
    decimal DiscountAmount,
    decimal TaxableAmount,
    decimal TaxAmount,
    decimal GrandTotal,
    decimal PaidAmount,
    decimal BalanceAmount,
    PaymentStatus PaymentStatus,
    InvoiceStatus InvoiceStatus,
    List<SyncInvoiceItemPushDto> Items,
    List<SyncPaymentPushDto> Payments);

public record SyncPushRequestDto(
    string DeviceId,
    string AppVersion,
    DateTime ClientSyncTimestampUtc,
    List<SyncCustomerPushDto> Customers,
    List<SyncInvoicePushDto> Invoices);

public record SyncedEntityMappingDto(
    Guid ClientGuid,
    long ServerId,
    string? ServerReference,
    bool WasAlreadySynced);

public record SyncPushResultDto(
    int TotalReceived,
    int TotalProcessed,
    int TotalFailed,
    List<SyncedEntityMappingDto> SyncedInvoices,
    List<SyncedEntityMappingDto> SyncedCustomers,
    List<string> Errors);

public record SyncPullRequestDto(
    string DeviceId,
    DateTime? LastSyncTimestampUtc = null);

public record SyncPullResponseDto(
    DateTime ServerSyncTimestampUtc,
    CompanyProfileDto? Company,
    List<CategoryDto> Categories,
    List<ProductDto> Products,
    List<TaxDto> Taxes,
    List<HsnSacDto> HsnSacs,
    GstConfigurationDto? GstConfiguration,
    List<CustomerDto> Customers,
    int TotalRecords);

public record SyncAuditLogDto(
    long Id,
    string DeviceId,
    string SyncType,
    string Status,
    int RecordsPushed,
    int RecordsPulled,
    int ConflictsCount,
    string? ErrorDetails,
    DateTime StartedAtUtc,
    DateTime CompletedAtUtc,
    long DurationMs);
