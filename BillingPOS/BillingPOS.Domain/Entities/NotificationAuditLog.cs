using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class NotificationAuditLog : BaseEntity
{
    public long InvoiceId { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public NotificationChannel Channel { get; set; }
    public string Recipient { get; set; } = string.Empty;
    public NotificationStatus Status { get; set; } = NotificationStatus.Pending;
    public DateTime? SentAtUtc { get; set; }
    public string? Subject { get; set; }
    public string MessageBody { get; set; } = string.Empty;
    public string? ExternalReferenceId { get; set; }
    public string? FailureReason { get; set; }
}

