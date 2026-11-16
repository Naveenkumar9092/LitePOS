namespace BillingPOS.Domain.Entities;

public class UserSession : BaseEntity<long>
{
    public long UserId { get; set; }
    public string SessionToken { get; set; } = string.Empty;
    public string? DeviceId { get; set; }
    public string? DeviceName { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime StartedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime LastActivityAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAtUtc { get; set; }
    public bool IsRevoked { get; set; }

    // Navigation properties
    public virtual User User { get; set; } = null!;
}

