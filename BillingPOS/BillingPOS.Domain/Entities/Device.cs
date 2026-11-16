namespace BillingPOS.Domain.Entities;

public class Device : BaseEntity<string>
{
    public string DeviceName { get; set; } = string.Empty;
    public DateTime? LastSyncTimeUtc { get; set; }
    public string AppVersion { get; set; } = "1.0.0";
    public bool IsOnline { get; set; } = true;
    public int SyncFailuresCount { get; set; }
    public DateTime RegisteredAtUtc { get; set; } = DateTime.UtcNow;
}

