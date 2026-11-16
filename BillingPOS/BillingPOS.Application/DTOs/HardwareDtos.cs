using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.DTOs;

public record PrinterConfigurationDto(
    long Id,
    string PrinterName,
    PrinterConnectionType ConnectionType,
    string? IpAddress,
    int Port,
    string? UsbDeviceName,
    string? BluetoothMacAddress,
    PrinterPaperSize PaperSize,
    int CharacterColumns,
    bool AutoCutReceipt,
    bool OpenCashDrawer,
    bool PrintLogo,
    bool PrintQrCode,
    int PrintCopies,
    string? HeaderCustomText,
    string? FooterCustomText,
    bool IsDefault,
    bool IsActive);

public record CreatePrinterConfigurationDto(
    string PrinterName,
    PrinterConnectionType ConnectionType,
    string? IpAddress = null,
    int Port = 9100,
    string? UsbDeviceName = null,
    string? BluetoothMacAddress = null,
    PrinterPaperSize PaperSize = PrinterPaperSize.Mm80,
    int? CharacterColumns = null,
    bool AutoCutReceipt = true,
    bool OpenCashDrawer = true,
    bool PrintLogo = false,
    bool PrintQrCode = true,
    int PrintCopies = 1,
    string? HeaderCustomText = null,
    string? FooterCustomText = null,
    bool IsDefault = false);

public record UpdatePrinterConfigurationDto(
    string PrinterName,
    PrinterConnectionType ConnectionType,
    string? IpAddress = null,
    int Port = 9100,
    string? UsbDeviceName = null,
    string? BluetoothMacAddress = null,
    PrinterPaperSize PaperSize = PrinterPaperSize.Mm80,
    int? CharacterColumns = null,
    bool AutoCutReceipt = true,
    bool OpenCashDrawer = true,
    bool PrintLogo = false,
    bool PrintQrCode = true,
    int PrintCopies = 1,
    string? HeaderCustomText = null,
    string? FooterCustomText = null,
    bool IsDefault = false,
    bool IsActive = true);

public record TestPrintResultDto(
    string PrinterName,
    PrinterPaperSize PaperSize,
    string Base64EscPosBytes,
    int ByteCount,
    string PlainTextPreview,
    DateTime GeneratedAtUtc);

public record ReceiptPrintResultDto(
    long InvoiceId,
    string InvoiceNumber,
    string PrinterName,
    PrinterPaperSize PaperSize,
    string Base64EscPosBytes,
    int ByteCount,
    string PlainTextPreview,
    DateTime GeneratedAtUtc);

public record CashDrawerCommandDto(
    string CommandName,
    string Base64EscPosBytes,
    string HexString);

