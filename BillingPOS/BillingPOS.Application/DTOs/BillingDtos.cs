using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public record CreateInvoiceItemDto(
    long ProductId,
    string? ProductNameSnapshot,
    int Quantity,
    decimal UnitPrice,
    decimal DiscountAmount = 0,
    decimal TaxPercentage = 0
);

public record CreateInvoiceDto(
    long? CustomerId,
    string? DeviceId,
    List<CreateInvoiceItemDto> Items,
    decimal DiscountAmount = 0,
    decimal PaidAmount = 0,
    PaymentMode PaymentMode = PaymentMode.Cash,
    string? TransactionReference = null
);

public record InvoiceItemDto(
    long InvoiceDetailId,
    long InvoiceId,
    long ProductId,
    string ProductNameSnapshot,
    decimal UnitPrice,
    int Quantity,
    decimal DiscountAmount,
    decimal TaxPercentage,
    decimal TaxAmount,
    decimal LineTotal
);

public record PaymentDto(
    long PaymentId,
    Guid PaymentGuid,
    long InvoiceId,
    PaymentMode PaymentMode,
    string PaymentModeName,
    decimal Amount,
    string? TransactionReference,
    PaymentStatus PaymentStatus,
    DateTime CreatedAtUtc
);

public record InvoiceDto(
    long InvoiceId,
    Guid InvoiceGuid,
    string InvoiceNumber,
    long CompanyId,
    string CompanyName,
    long ShopId,
    string ShopName,
    long? CustomerId,
    string? CustomerName,
    string? CustomerMobile,
    long CashierId,
    string CashierName,
    string DeviceId,
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
    SyncStatus SyncStatus,
    List<InvoiceItemDto> Items,
    List<PaymentDto> Payments,
    DateTime CreatedAtUtc
);

public record HoldBillDto(
    long? CustomerId,
    string? DeviceId,
    string? Note,
    List<CreateInvoiceItemDto> Items,
    decimal DiscountAmount = 0
);

public record ResumeBillDto(
    long InvoiceId
);

public record CancelBillDto(
    string Reason
);

public record PagedInvoicesResultDto(
    List<InvoiceDto> Items,
    int TotalCount,
    int PageNumber,
    int PageSize
);

