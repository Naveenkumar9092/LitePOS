namespace BillingPOS.Domain.Entities;

public class LoginAuditLog : BaseEntity<long>
{
    public long? UserId { get; set; }
    public string UsernameAttempted { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? DeviceId { get; set; }
    public string? FailureReason { get; set; }
    public DateTime AttemptedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation property
    public virtual User? User { get; set; }
}

