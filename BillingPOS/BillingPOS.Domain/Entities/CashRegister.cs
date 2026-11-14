namespace BillingPOS.Domain.Entities;

public class CashRegister : BaseEntity<long>
{
    public Guid SessionGuid { get; set; } = Guid.NewGuid();
    public long ShopId { get; set; } = 1;
    public long CashierId { get; set; } = 1;
    public string CashierUsername { get; set; } = "Cashier";
    public string DeviceId { get; set; } = "POS-TERMINAL-01";
    public decimal OpeningFloat { get; set; }
    public DateTime OpeningTimeUtc { get; set; } = DateTime.UtcNow;
    public string? OpeningNotes { get; set; }
    public DateTime? ClosingTimeUtc { get; set; }
    public decimal? ActualCash { get; set; }
    public decimal? ExpectedCash { get; set; }
    public decimal? Discrepancy { get; set; }
    public string? ClosingNotes { get; set; }
    public bool IsOpen { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

