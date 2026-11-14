using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public class SendInvoiceNotificationDto
{
    public long InvoiceId { get; set; }
    public NotificationChannel Channel { get; set; }
    public string? RecipientOverride { get; set; }
    public bool IncludePaymentQr { get; set; } = true;
}

public class NotificationResultDto
{
    public bool Success { get; set; }
    public NotificationChannel Channel { get; set; }
    public string Recipient { get; set; } = string.Empty;
    public string InvoiceNumber { get; set; } = string.Empty;
    public string MessageId { get; set; } = string.Empty;
    public DateTime SentAtUtc { get; set; }
    public string Message { get; set; } = string.Empty;
    public string PreviewSnippet { get; set; } = string.Empty;
}

public class NotificationAuditLogDto
{
    public long Id { get; set; }
    public long InvoiceId { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public NotificationChannel Channel { get; set; }
    public string Recipient { get; set; } = string.Empty;
    public NotificationStatus Status { get; set; }
    public DateTime? SentAtUtc { get; set; }
    public string? Subject { get; set; }
    public string MessageBody { get; set; } = string.Empty;
    public string? ExternalReferenceId { get; set; }
    public string? FailureReason { get; set; }
}

