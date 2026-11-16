using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public class ProcessPaymentDto
{
    public long InvoiceId { get; set; }
    public PaymentMode PaymentMode { get; set; } = PaymentMode.Cash;
    public decimal Amount { get; set; }
    public string? TransactionReference { get; set; }
    public string? Notes { get; set; }
}

public class SplitPaymentItemDto
{
    public PaymentMode PaymentMode { get; set; }
    public decimal Amount { get; set; }
    public string? TransactionReference { get; set; }
}

public class ProcessSplitPaymentDto
{
    public long InvoiceId { get; set; }
    public List<SplitPaymentItemDto> Payments { get; set; } = new();
}

public class ProcessRefundDto
{
    public long InvoiceId { get; set; }
    public long? PaymentId { get; set; }
    public decimal Amount { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? AuthorizedBy { get; set; }
}

public class PaymentTransactionDto
{
    public long Id { get; set; }
    public Guid PaymentGuid { get; set; }
    public long InvoiceId { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public PaymentMode PaymentMode { get; set; }
    public string PaymentModeName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string? TransactionReference { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    public string PaymentStatusName => PaymentStatus.ToString();
    public DateTime CreatedAtUtc { get; set; }
    public string? CashierUsername { get; set; }
    public string? CustomerName { get; set; }
}

public class PaymentFilterDto
{
    public long? InvoiceId { get; set; }
    public PaymentMode? PaymentMode { get; set; }
    public PaymentStatus? PaymentStatus { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? SearchTerm { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class PagedPaymentsResultDto
{
    public List<PaymentTransactionDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
}

public class PaymentReconciliationDto
{
    public DateTime Date { get; set; }
    public decimal OpeningFloat { get; set; }
    public decimal CashCollected { get; set; }
    public decimal UpiCollected { get; set; }
    public decimal CardCollected { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal NetCollected { get; set; }
    public int TotalTransactions { get; set; }
    public decimal ExpectedCashInDrawer { get; set; }
    public decimal? ActualCashInDrawer { get; set; }
    public decimal? CashDifference { get; set; }
    public bool IsRegisterOpen { get; set; }
    public string? CurrentSessionGuid { get; set; }
}

public class OpenCashRegisterDto
{
    public decimal OpeningFloat { get; set; }
    public string? Notes { get; set; }
    public string? DeviceId { get; set; }
}

public class CloseCashRegisterDto
{
    public decimal ActualCash { get; set; }
    public string? Notes { get; set; }
}

public class CashRegisterSessionDto
{
    public long Id { get; set; }
    public Guid SessionGuid { get; set; }
    public string CashierUsername { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public decimal OpeningFloat { get; set; }
    public DateTime OpeningTimeUtc { get; set; }
    public string? OpeningNotes { get; set; }
    public DateTime? ClosingTimeUtc { get; set; }
    public decimal? ActualCash { get; set; }
    public decimal? ExpectedCash { get; set; }
    public decimal? Discrepancy { get; set; }
    public string? ClosingNotes { get; set; }
    public bool IsOpen { get; set; }
}
