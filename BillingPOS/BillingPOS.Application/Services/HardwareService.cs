using System.Globalization;
using System.Text;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class HardwareService : IHardwareService
{
    private readonly IRepository<PrinterConfiguration> _printerRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<GstConfiguration> _gstConfigRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<CreatePrinterConfigurationDto> _createValidator;
    private readonly IValidator<UpdatePrinterConfigurationDto> _updateValidator;
    private readonly ILogger<HardwareService> _logger;

    // ESC/POS Command Byte Constants
    private static readonly byte[] EscInit = { 0x1B, 0x40 }; // ESC @
    private static readonly byte[] EscAlignLeft = { 0x1B, 0x61, 0x00 };
    private static readonly byte[] EscAlignCenter = { 0x1B, 0x61, 0x01 };
    private static readonly byte[] EscAlignRight = { 0x1B, 0x61, 0x02 };
    private static readonly byte[] EscBoldOn = { 0x1B, 0x45, 0x01 };
    private static readonly byte[] EscBoldOff = { 0x1B, 0x45, 0x00 };
    private static readonly byte[] EscDoubleSize = { 0x1D, 0x21, 0x11 };
    private static readonly byte[] EscNormalSize = { 0x1D, 0x21, 0x00 };
    private static readonly byte[] EscDrawerKick = { 0x1B, 0x70, 0x00, 0x19, 0xFA }; // Pin 2 (Standard)
    private static readonly byte[] EscCutPaper = { 0x1D, 0x56, 0x42, 0x00 }; // GS V 66 0 (Feed & Full Cut)
    private static readonly byte[] EscLineFeed = { 0x0A };

    public HardwareService(
        IRepository<PrinterConfiguration> printerRepository,
        IRepository<Invoice> invoiceRepository,
        IRepository<Company> companyRepository,
        IRepository<GstConfiguration> gstConfigRepository,
        IUnitOfWork unitOfWork,
        IDateTimeService dateTimeService,
        IValidator<CreatePrinterConfigurationDto> createValidator,
        IValidator<UpdatePrinterConfigurationDto> updateValidator,
        ILogger<HardwareService> logger)
    {
        _printerRepository = printerRepository;
        _invoiceRepository = invoiceRepository;
        _companyRepository = companyRepository;
        _gstConfigRepository = gstConfigRepository;
        _unitOfWork = unitOfWork;
        _dateTimeService = dateTimeService;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
        _logger = logger;
    }

    public async Task<List<PrinterConfigurationDto>> GetPrintersAsync(CancellationToken cancellationToken = default)
    {
        var printers = await _printerRepository.Query().AsNoTracking()
            .Where(p => p.IsActive)
            .OrderByDescending(p => p.IsDefault)
            .ThenBy(p => p.PrinterName)
            .ToListAsync(cancellationToken);

        return printers.Select(MapToDto).ToList();
    }

    public async Task<PrinterConfigurationDto?> GetPrinterByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var printer = await _printerRepository.GetByIdAsync(id, cancellationToken);
        return printer != null && printer.IsActive ? MapToDto(printer) : null;
    }

    public async Task<PrinterConfigurationDto> GetDefaultPrinterAsync(CancellationToken cancellationToken = default)
    {
        var printer = await _printerRepository.Query().AsNoTracking()
            .FirstOrDefaultAsync(p => p.IsActive && p.IsDefault, cancellationToken);

        if (printer != null)
        {
            return MapToDto(printer);
        }

        var anyActive = await _printerRepository.Query().AsNoTracking()
            .FirstOrDefaultAsync(p => p.IsActive, cancellationToken);

        if (anyActive != null)
        {
            return MapToDto(anyActive);
        }

        // Return virtual default 80mm configuration if database is empty
        return new PrinterConfigurationDto(
            Id: 0,
            PrinterName: "Standard Thermal Printer (80mm)",
            ConnectionType: PrinterConnectionType.Network,
            IpAddress: "192.168.1.100",
            Port: 9100,
            UsbDeviceName: null,
            BluetoothMacAddress: null,
            PaperSize: PrinterPaperSize.Mm80,
            CharacterColumns: 48,
            AutoCutReceipt: true,
            OpenCashDrawer: true,
            PrintLogo: false,
            PrintQrCode: true,
            PrintCopies: 1,
            HeaderCustomText: "Welcome to Cafe Bliss",
            FooterCustomText: "Thank You! Visit Again",
            IsDefault: true,
            IsActive: true);
    }

    public async Task<PrinterConfigurationDto> CreatePrinterAsync(CreatePrinterConfigurationDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _createValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
        {
            throw new ValidationException(validation.Errors);
        }

        if (dto.IsDefault)
        {
            await ClearDefaultPrintersAsync(cancellationToken);
        }

        var cols = dto.CharacterColumns ?? (dto.PaperSize == PrinterPaperSize.Mm58 ? 32 : 48);

        var entity = new PrinterConfiguration
        {
            CompanyId = 1,
            ShopId = 1,
            PrinterName = dto.PrinterName,
            ConnectionType = dto.ConnectionType,
            IpAddress = dto.IpAddress,
            Port = dto.Port,
            UsbDeviceName = dto.UsbDeviceName,
            BluetoothMacAddress = dto.BluetoothMacAddress,
            PaperSize = dto.PaperSize,
            CharacterColumns = cols,
            AutoCutReceipt = dto.AutoCutReceipt,
            OpenCashDrawer = dto.OpenCashDrawer,
            PrintLogo = dto.PrintLogo,
            PrintQrCode = dto.PrintQrCode,
            PrintCopies = dto.PrintCopies,
            HeaderCustomText = dto.HeaderCustomText,
            FooterCustomText = dto.FooterCustomText,
            IsDefault = dto.IsDefault,
            IsActive = true
        };

        await _printerRepository.AddAsync(entity, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Printer {PrinterName} created with ID {Id}.", entity.PrinterName, entity.Id);
        return MapToDto(entity);
    }

    public async Task<PrinterConfigurationDto> UpdatePrinterAsync(long id, UpdatePrinterConfigurationDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _updateValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
        {
            throw new ValidationException(validation.Errors);
        }

        var entity = await _printerRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
        {
            throw new KeyNotFoundException($"Printer configuration with ID #{id} not found.");
        }

        if (dto.IsDefault && !entity.IsDefault)
        {
            await ClearDefaultPrintersAsync(cancellationToken);
        }

        var cols = dto.CharacterColumns ?? (dto.PaperSize == PrinterPaperSize.Mm58 ? 32 : 48);

        entity.PrinterName = dto.PrinterName;
        entity.ConnectionType = dto.ConnectionType;
        entity.IpAddress = dto.IpAddress;
        entity.Port = dto.Port;
        entity.UsbDeviceName = dto.UsbDeviceName;
        entity.BluetoothMacAddress = dto.BluetoothMacAddress;
        entity.PaperSize = dto.PaperSize;
        entity.CharacterColumns = cols;
        entity.AutoCutReceipt = dto.AutoCutReceipt;
        entity.OpenCashDrawer = dto.OpenCashDrawer;
        entity.PrintLogo = dto.PrintLogo;
        entity.PrintQrCode = dto.PrintQrCode;
        entity.PrintCopies = dto.PrintCopies;
        entity.HeaderCustomText = dto.HeaderCustomText;
        entity.FooterCustomText = dto.FooterCustomText;
        entity.IsDefault = dto.IsDefault;
        entity.IsActive = dto.IsActive;

        _printerRepository.Update(entity);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Printer #{Id} updated.", entity.Id);
        return MapToDto(entity);
    }

    public async Task<bool> DeletePrinterAsync(long id, CancellationToken cancellationToken = default)
    {
        var entity = await _printerRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            return false;

        entity.IsActive = false;
        _printerRepository.Update(entity);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Printer #{Id} deactivated.", id);
        return true;
    }

    public async Task<PrinterConfigurationDto> SetDefaultPrinterAsync(long id, CancellationToken cancellationToken = default)
    {
        var target = await _printerRepository.GetByIdAsync(id, cancellationToken);
        if (target == null)
        {
            throw new KeyNotFoundException($"Printer configuration with ID #{id} not found.");
        }

        await ClearDefaultPrintersAsync(cancellationToken);

        target.IsDefault = true;
        _printerRepository.Update(target);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(target);
    }

    public CashDrawerCommandDto GenerateOpenCashDrawerCommand()
    {
        var bytes = EscDrawerKick;
        var hex = BitConverter.ToString(bytes).Replace("-", " ");
        var b64 = Convert.ToBase64String(bytes);

        return new CashDrawerCommandDto(
            CommandName: "Open Cash Drawer (ESC p 0 25 250)",
            Base64EscPosBytes: b64,
            HexString: hex);
    }

    public async Task<TestPrintResultDto> GenerateTestPrintAsync(long? printerId = null, CancellationToken cancellationToken = default)
    {
        var printer = printerId.HasValue
            ? await GetPrinterByIdAsync(printerId.Value, cancellationToken) ?? await GetDefaultPrinterAsync(cancellationToken)
            : await GetDefaultPrinterAsync(cancellationToken);

        var width = printer.CharacterColumns > 0 ? printer.CharacterColumns : (printer.PaperSize == PrinterPaperSize.Mm58 ? 32 : 48);
        var divider = new string('-', width);
        var doubleDivider = new string('=', width);

        var preview = new StringBuilder();
        var buffer = new List<byte>();

        // Init
        buffer.AddRange(EscInit);

        // Header
        buffer.AddRange(EscAlignCenter);
        buffer.AddRange(EscBoldOn);
        buffer.AddRange(EscDoubleSize);
        buffer.AddRange(Encoding.ASCII.GetBytes("HARDWARE TEST\n"));
        preview.AppendLine("HARDWARE TEST".PadCenter(width));

        buffer.AddRange(EscNormalSize);
        buffer.AddRange(Encoding.ASCII.GetBytes("ESC/POS Thermal Printer\n"));
        preview.AppendLine("ESC/POS Thermal Printer".PadCenter(width));
        buffer.AddRange(EscBoldOff);

        buffer.AddRange(Encoding.ASCII.GetBytes(doubleDivider + "\n"));
        preview.AppendLine(doubleDivider);

        // Body Details
        buffer.AddRange(EscAlignLeft);
        AppendKeyValue(buffer, preview, "Printer Name:", printer.PrinterName, width);
        AppendKeyValue(buffer, preview, "Connection:", printer.ConnectionType.ToString(), width);
        if (printer.ConnectionType == PrinterConnectionType.Network)
        {
            AppendKeyValue(buffer, preview, "IP / Port:", $"{printer.IpAddress}:{printer.Port}", width);
        }
        AppendKeyValue(buffer, preview, "Paper Roll:", printer.PaperSize == PrinterPaperSize.Mm80 ? "80mm (Wide)" : "58mm (Compact)", width);
        AppendKeyValue(buffer, preview, "Columns:", $"{width} Characters", width);
        AppendKeyValue(buffer, preview, "Auto-Cut:", printer.AutoCutReceipt ? "Enabled" : "Disabled", width);
        AppendKeyValue(buffer, preview, "Drawer Kick:", printer.OpenCashDrawer ? "Enabled" : "Disabled", width);
        AppendKeyValue(buffer, preview, "Test Time:", _dateTimeService.UtcNow.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture), width);

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Column Alignment Test
        buffer.AddRange(EscAlignCenter);
        buffer.AddRange(Encoding.ASCII.GetBytes("1234567890123456789012345678901234567890\n"[..Math.Min(40, width)] + "\n"));
        buffer.AddRange(Encoding.ASCII.GetBytes("** PRINTER WORKING PERFECTLY **\n"));
        preview.AppendLine("** PRINTER WORKING PERFECTLY **".PadCenter(width));

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Feed & Cut
        buffer.AddRange(EscLineFeed);
        buffer.AddRange(EscLineFeed);
        buffer.AddRange(EscLineFeed);

        if (printer.OpenCashDrawer)
        {
            buffer.AddRange(EscDrawerKick);
        }

        if (printer.AutoCutReceipt)
        {
            buffer.AddRange(EscCutPaper);
        }

        var b64 = Convert.ToBase64String(buffer.ToArray());

        return new TestPrintResultDto(
            PrinterName: printer.PrinterName,
            PaperSize: printer.PaperSize,
            Base64EscPosBytes: b64,
            ByteCount: buffer.Count,
            PlainTextPreview: preview.ToString(),
            GeneratedAtUtc: _dateTimeService.UtcNow);
    }

    public async Task<ReceiptPrintResultDto> GenerateInvoiceReceiptEscPosAsync(long invoiceId, long? printerId = null, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoiceRepository.Query().AsNoTracking()
            .Include(i => i.Items)
            .Include(i => i.Payments)
            .Include(i => i.Customer)
            .Include(i => i.Cashier)
            .Include(i => i.Shop)
            .Include(i => i.Company)
            .FirstOrDefaultAsync(i => i.Id == invoiceId, cancellationToken);

        if (invoice == null)
        {
            throw new KeyNotFoundException($"Invoice #{invoiceId} not found.");
        }

        var printer = printerId.HasValue
            ? await GetPrinterByIdAsync(printerId.Value, cancellationToken) ?? await GetDefaultPrinterAsync(cancellationToken)
            : await GetDefaultPrinterAsync(cancellationToken);

        var gstConfig = await _gstConfigRepository.Query().AsNoTracking().FirstOrDefaultAsync(cancellationToken);

        var width = printer.CharacterColumns > 0 ? printer.CharacterColumns : (printer.PaperSize == PrinterPaperSize.Mm58 ? 32 : 48);
        var divider = new string('-', width);
        var doubleDivider = new string('=', width);

        var preview = new StringBuilder();
        var buffer = new List<byte>();

        // Init
        buffer.AddRange(EscInit);

        // Shop Header
        var shopName = invoice.Company?.CompanyName ?? gstConfig?.TradeName ?? "Cafe Bliss POS";
        var shopAddress = invoice.Shop?.AddressLine1 ?? "Main Road, Chennai";
        var gstin = gstConfig?.GSTIN ?? invoice.Company?.GSTIN ?? "33AAAAA0000A1Z5";
        var contact = invoice.Shop?.ContactNumber ?? invoice.Company?.MobileNumber ?? "9876543210";

        buffer.AddRange(EscAlignCenter);
        buffer.AddRange(EscBoldOn);
        buffer.AddRange(EscDoubleSize);
        buffer.AddRange(Encoding.ASCII.GetBytes(shopName + "\n"));
        preview.AppendLine(shopName.PadCenter(width));

        buffer.AddRange(EscNormalSize);
        buffer.AddRange(EscBoldOff);

        if (!string.IsNullOrWhiteSpace(printer.HeaderCustomText))
        {
            buffer.AddRange(Encoding.ASCII.GetBytes(printer.HeaderCustomText + "\n"));
            preview.AppendLine(printer.HeaderCustomText.PadCenter(width));
        }

        buffer.AddRange(Encoding.ASCII.GetBytes(shopAddress + "\n"));
        preview.AppendLine(shopAddress.PadCenter(width));
        buffer.AddRange(Encoding.ASCII.GetBytes($"GSTIN: {gstin} | Tel: {contact}\n"));
        preview.AppendLine($"GSTIN: {gstin} | Tel: {contact}".PadCenter(width));

        buffer.AddRange(Encoding.ASCII.GetBytes(doubleDivider + "\n"));
        preview.AppendLine(doubleDivider);

        // Invoice Meta
        buffer.AddRange(EscAlignLeft);
        AppendKeyValue(buffer, preview, "Invoice No:", invoice.InvoiceNumber, width);
        AppendKeyValue(buffer, preview, "Date & Time:", invoice.InvoiceDateUtc.ToString("dd/MM/yyyy hh:mm tt", CultureInfo.InvariantCulture), width);
        AppendKeyValue(buffer, preview, "Cashier:", invoice.Cashier?.FullName ?? "Cashier", width);
        if (invoice.Customer != null)
        {
            AppendKeyValue(buffer, preview, "Customer:", $"{invoice.Customer.CustomerName} ({invoice.Customer.MobileNumber})", width);
        }

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Table Header
        string tableHeader;
        if (width >= 48) // 80mm format
        {
            tableHeader = string.Format("{0,-24} {1,4} {2,8} {3,9}", "ITEM", "QTY", "RATE", "TOTAL");
        }
        else // 58mm format
        {
            tableHeader = string.Format("{0,-14} {1,3} {2,6} {3,6}", "ITEM", "QTY", "RATE", "AMT");
        }

        buffer.AddRange(EscBoldOn);
        buffer.AddRange(Encoding.ASCII.GetBytes(tableHeader + "\n"));
        preview.AppendLine(tableHeader);
        buffer.AddRange(EscBoldOff);

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Item Rows
        foreach (var item in invoice.Items)
        {
            var name = item.ProductNameSnapshot;
            string row;
            if (width >= 48)
            {
                var truncatedName = name.Length > 24 ? name[..24] : name;
                row = string.Format(CultureInfo.InvariantCulture, "{0,-24} {1,4} {2,8:F2} {3,9:F2}", truncatedName, item.Quantity, item.UnitPrice, item.LineTotal);
            }
            else
            {
                var truncatedName = name.Length > 14 ? name[..14] : name;
                row = string.Format(CultureInfo.InvariantCulture, "{0,-14} {1,3} {2,6:F1} {3,6:F1}", truncatedName, item.Quantity, item.UnitPrice, item.LineTotal);
            }

            buffer.AddRange(Encoding.ASCII.GetBytes(row + "\n"));
            preview.AppendLine(row);
        }

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Financial Totals
        AppendKeyValue(buffer, preview, "SubTotal:", $"Rs.{invoice.SubTotal:F2}", width);
        if (invoice.DiscountAmount > 0)
        {
            AppendKeyValue(buffer, preview, "Discount:", $"-Rs.{invoice.DiscountAmount:F2}", width);
        }
        AppendKeyValue(buffer, preview, "Taxable Amount:", $"Rs.{invoice.TaxableAmount:F2}", width);

        // 50/50 CGST & SGST
        var cgst = Math.Round(invoice.TaxAmount / 2, 2);
        var sgst = Math.Round(invoice.TaxAmount - cgst, 2);
        AppendKeyValue(buffer, preview, "CGST (Central Tax):", $"Rs.{cgst:F2}", width);
        AppendKeyValue(buffer, preview, "SGST (State Tax):", $"Rs.{sgst:F2}", width);

        buffer.AddRange(Encoding.ASCII.GetBytes(doubleDivider + "\n"));
        preview.AppendLine(doubleDivider);

        // Grand Total (Bold)
        buffer.AddRange(EscBoldOn);
        buffer.AddRange(EscDoubleSize);
        AppendKeyValue(buffer, preview, "GRAND TOTAL:", $"Rs.{invoice.GrandTotal:F2}", width);
        buffer.AddRange(EscNormalSize);
        buffer.AddRange(EscBoldOff);

        buffer.AddRange(Encoding.ASCII.GetBytes(doubleDivider + "\n"));
        preview.AppendLine(doubleDivider);

        // Payments Breakdown
        foreach (var pay in invoice.Payments)
        {
            AppendKeyValue(buffer, preview, $"Paid ({pay.PaymentMode}):", $"Rs.{pay.Amount:F2}", width);
        }
        if (invoice.BalanceAmount > 0)
        {
            AppendKeyValue(buffer, preview, "Balance Due:", $"Rs.{invoice.BalanceAmount:F2}", width);
        }

        buffer.AddRange(Encoding.ASCII.GetBytes(divider + "\n"));
        preview.AppendLine(divider);

        // Footer & QR Code
        buffer.AddRange(EscAlignCenter);
        if (printer.PrintQrCode)
        {
            // UPI QR Payload text
            var upiPayload = $"upi://pay?pa={gstin}@upi&pn={Uri.EscapeDataString(shopName)}&am={invoice.GrandTotal:F2}&tr={invoice.InvoiceNumber}&cu=INR";
            buffer.AddRange(Encoding.ASCII.GetBytes("[SCAN TO PAY VIA UPI]\n"));
            preview.AppendLine("[SCAN TO PAY VIA UPI]".PadCenter(width));
            buffer.AddRange(Encoding.ASCII.GetBytes($"{upiPayload}\n"));
            preview.AppendLine(upiPayload.PadCenter(width));
        }

        var footer = printer.FooterCustomText ?? "Thank You! Please Visit Again";
        buffer.AddRange(Encoding.ASCII.GetBytes(footer + "\n"));
        preview.AppendLine(footer.PadCenter(width));

        // Feed & Cut
        buffer.AddRange(EscLineFeed);
        buffer.AddRange(EscLineFeed);
        buffer.AddRange(EscLineFeed);

        if (printer.OpenCashDrawer)
        {
            buffer.AddRange(EscDrawerKick);
        }

        if (printer.AutoCutReceipt)
        {
            buffer.AddRange(EscCutPaper);
        }

        var b64 = Convert.ToBase64String(buffer.ToArray());

        return new ReceiptPrintResultDto(
            InvoiceId: invoice.Id,
            InvoiceNumber: invoice.InvoiceNumber,
            PrinterName: printer.PrinterName,
            PaperSize: printer.PaperSize,
            Base64EscPosBytes: b64,
            ByteCount: buffer.Count,
            PlainTextPreview: preview.ToString(),
            GeneratedAtUtc: _dateTimeService.UtcNow);
    }

    private async Task ClearDefaultPrintersAsync(CancellationToken cancellationToken)
    {
        var existingDefaults = await _printerRepository.Query()
            .Where(p => p.IsDefault)
            .ToListAsync(cancellationToken);

        foreach (var p in existingDefaults)
        {
            p.IsDefault = false;
            _printerRepository.Update(p);
        }
    }

    private static void AppendKeyValue(List<byte> buffer, StringBuilder preview, string key, string value, int width)
    {
        var availableSpace = width - key.Length;
        var paddedValue = availableSpace > 0 ? value.PadLeft(availableSpace) : value;
        var line = $"{key}{paddedValue}\n";
        buffer.AddRange(Encoding.ASCII.GetBytes(line));
        preview.Append(line);
    }

    private static PrinterConfigurationDto MapToDto(PrinterConfiguration p)
    {
        return new PrinterConfigurationDto(
            p.Id,
            p.PrinterName,
            p.ConnectionType,
            p.IpAddress,
            p.Port,
            p.UsbDeviceName,
            p.BluetoothMacAddress,
            p.PaperSize,
            p.CharacterColumns,
            p.AutoCutReceipt,
            p.OpenCashDrawer,
            p.PrintLogo,
            p.PrintQrCode,
            p.PrintCopies,
            p.HeaderCustomText,
            p.FooterCustomText,
            p.IsDefault,
            p.IsActive);
    }
}

public static class StringExtensions
{
    public static string PadCenter(this string str, int width)
    {
        if (string.IsNullOrEmpty(str) || width <= str.Length)
            return str;

        var spaces = width - str.Length;
        var padLeft = spaces / 2 + str.Length;
        return str.PadLeft(padLeft).PadRight(width);
    }
}

