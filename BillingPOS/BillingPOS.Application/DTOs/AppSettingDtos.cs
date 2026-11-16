namespace BillingPOS.Application.DTOs;

public class ShopPreferenceDto
{
    public long Id { get; set; }
    public long ShopId { get; set; }
    public bool EnableEmailInvoicing { get; set; }
    public bool EnableWhatsAppInvoicing { get; set; }
    public bool AutoSendInvoiceOnPayment { get; set; }
    public string? ReceiptHeaderCustom { get; set; }
    public string? ReceiptFooterCustom { get; set; }
    public decimal DefaultGstRate { get; set; }
    public bool EnableSoundAlerts { get; set; }
    public string? BackupDirectoryPath { get; set; }
    public DateTime? LastBackupUtc { get; set; }
    public string AppVersion { get; set; } = "1.0.0";
}

public class UpdateShopPreferenceDto
{
    public bool EnableEmailInvoicing { get; set; }
    public bool EnableWhatsAppInvoicing { get; set; }
    public bool AutoSendInvoiceOnPayment { get; set; }
    public string? ReceiptHeaderCustom { get; set; }
    public string? ReceiptFooterCustom { get; set; }
    public decimal DefaultGstRate { get; set; } = 5.0m;
    public bool EnableSoundAlerts { get; set; }
    public string? BackupDirectoryPath { get; set; }
}

public class DatabaseBackupResultDto
{
    public string BackupFileName { get; set; } = string.Empty;
    public long BackupSizeBytes { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public string BackupLocation { get; set; } = string.Empty;
    public string Status { get; set; } = "Completed";
    public string Message { get; set; } = string.Empty;
}

public class SystemInfoSummaryDto
{
    public string AppName { get; set; } = "LitePOS Billing Software";
    public string AppVersion { get; set; } = "1.0.0";
    public string Environment { get; set; } = "Production";
    public string DatabaseEngine { get; set; } = "Microsoft SQL Server";
    public bool DatabaseConnected { get; set; } = true;
    public int TotalInvoices { get; set; }
    public int TotalProducts { get; set; }
    public int TotalCustomers { get; set; }
    public int ActivePrinters { get; set; }
    public DateTime? LastSyncUtc { get; set; }
    public DateTime? LastBackupUtc { get; set; }
    public DateTime ServerTimeUtc { get; set; }
}

