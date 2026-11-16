namespace BillingPOS.Domain.Entities;

public class ShopPreference : BaseEntity
{
    public long ShopId { get; set; } = 1;
    public bool EnableEmailInvoicing { get; set; } = true;
    public bool EnableWhatsAppInvoicing { get; set; } = true;
    public bool AutoSendInvoiceOnPayment { get; set; } = false;
    public string? ReceiptHeaderCustom { get; set; }
    public string? ReceiptFooterCustom { get; set; }
    public decimal DefaultGstRate { get; set; } = 5.0m;
    public bool EnableSoundAlerts { get; set; } = true;
    public string? BackupDirectoryPath { get; set; }
    public DateTime? LastBackupUtc { get; set; }
    public string AppVersion { get; set; } = "1.0.0";
}

