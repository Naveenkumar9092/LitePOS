namespace BillingPOS.Domain.Entities;

public class SyncAuditLog : BaseEntity<long>
{
    public string DeviceId { get; set; } = string.Empty;
    public string SyncType { get; set; } = "Full"; // Push, Pull, Full
    public string Status { get; set; } = "Success"; // Success, Failed, Partial
    public int RecordsPushed { get; set; }
    public int RecordsPulled { get; set; }
    public int ConflictsCount { get; set; }
    public string? ErrorDetails { get; set; }
    public DateTime StartedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime CompletedAtUtc { get; set; } = DateTime.UtcNow;
    public long DurationMs { get; set; }
}

