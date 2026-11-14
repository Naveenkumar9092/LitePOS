using BillingPOS.Domain.Enums;

namespace BillingPOS.Domain.Entities;

public class PrinterConfiguration : AuditableEntity<long>
{
    public long CompanyId { get; set; } = 1;
    public long ShopId { get; set; } = 1;
    public string PrinterName { get; set; } = "Thermal Receipt Printer";
    public PrinterConnectionType ConnectionType { get; set; } = PrinterConnectionType.Network;
    public string? IpAddress { get; set; } = "192.168.1.100";
    public int Port { get; set; } = 9100;
    public string? UsbDeviceName { get; set; }
    public string? BluetoothMacAddress { get; set; }
    public PrinterPaperSize PaperSize { get; set; } = PrinterPaperSize.Mm80;
    public int CharacterColumns { get; set; } = 48;
    public bool AutoCutReceipt { get; set; } = true;
    public bool OpenCashDrawer { get; set; } = true;
    public bool PrintLogo { get; set; } = false;
    public bool PrintQrCode { get; set; } = true;
    public int PrintCopies { get; set; } = 1;
    public string? HeaderCustomText { get; set; }
    public string? FooterCustomText { get; set; }
    public bool IsDefault { get; set; } = true;

    // Navigation property
    public virtual Company Company { get; set; } = null!;
    public virtual Shop Shop { get; set; } = null!;
}

