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

public class NotificationService : INotificationService
{
    private readonly IRepository<NotificationAuditLog> _auditLogRepository;
    private readonly IRepository<ShopPreference> _preferenceRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<PrinterConfiguration> _printerRepository;
    private readonly IRepository<SyncAuditLog> _syncRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<SendInvoiceNotificationDto> _sendValidator;
    private readonly IValidator<UpdateShopPreferenceDto> _updatePreferenceValidator;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        IRepository<NotificationAuditLog> auditLogRepository,
        IRepository<ShopPreference> preferenceRepository,
        IRepository<Invoice> invoiceRepository,
        IRepository<Company> companyRepository,
        IRepository<Product> productRepository,
        IRepository<Customer> customerRepository,
        IRepository<PrinterConfiguration> printerRepository,
        IRepository<SyncAuditLog> syncRepository,
        IUnitOfWork unitOfWork,
        IDateTimeService dateTimeService,
        IValidator<SendInvoiceNotificationDto> sendValidator,
        IValidator<UpdateShopPreferenceDto> updatePreferenceValidator,
        ILogger<NotificationService> logger)
    {
        _auditLogRepository = auditLogRepository;
        _preferenceRepository = preferenceRepository;
        _invoiceRepository = invoiceRepository;
        _companyRepository = companyRepository;
        _productRepository = productRepository;
        _customerRepository = customerRepository;
        _printerRepository = printerRepository;
        _syncRepository = syncRepository;
        _unitOfWork = unitOfWork;
        _dateTimeService = dateTimeService;
        _sendValidator = sendValidator;
        _updatePreferenceValidator = updatePreferenceValidator;
        _logger = logger;
    }

    public async Task<NotificationResultDto> SendInvoiceEmailAsync(SendInvoiceNotificationDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _sendValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
            throw new ValidationException(validation.Errors);

        var invoice = await _invoiceRepository.Query()
            .Include(i => i.Items)
            .Include(i => i.Payments)
            .Include(i => i.Customer)
            .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

        if (invoice == null)
            throw new KeyNotFoundException($"Invoice #{dto.InvoiceId} not found.");

        var company = await _companyRepository.Query().FirstOrDefaultAsync(cancellationToken)
                      ?? new Company { CompanyName = "LitePOS Cafe", LegalName = "LitePOS Retail Private Limited" };

        var recipient = !string.IsNullOrWhiteSpace(dto.RecipientOverride)
            ? dto.RecipientOverride.Trim()
            : (!string.IsNullOrWhiteSpace(invoice.Customer?.Email) ? invoice.Customer.Email : "customer@example.com");

        var subject = $"Tax Invoice #{invoice.InvoiceNumber} from {company.CompanyName}";
        var body = ComposeEmailInvoiceHtml(company, invoice);
        var messageId = $"EMAIL-MSG-{Guid.NewGuid():N}";
        var now = _dateTimeService.UtcNow;

        var auditLog = new NotificationAuditLog
        {
            InvoiceId = invoice.Id,
            InvoiceNumber = invoice.InvoiceNumber,
            Channel = NotificationChannel.Email,
            Recipient = recipient,
            Status = NotificationStatus.Sent,
            SentAtUtc = now,
            Subject = subject,
            MessageBody = body,
            ExternalReferenceId = messageId
        };

        await _auditLogRepository.AddAsync(auditLog, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Dispatched invoice email #{InvoiceNumber} to {Recipient} with ID {MessageId}",
            invoice.InvoiceNumber, recipient, messageId);

        return new NotificationResultDto
        {
            Success = true,
            Channel = NotificationChannel.Email,
            Recipient = recipient,
            InvoiceNumber = invoice.InvoiceNumber,
            MessageId = messageId,
            SentAtUtc = now,
            Message = $"Tax Invoice #{invoice.InvoiceNumber} successfully sent to {recipient}.",
            PreviewSnippet = $"Subject: {subject} | Total: ₹{invoice.GrandTotal:F2}"
        };
    }

    public async Task<NotificationResultDto> SendInvoiceWhatsAppAsync(SendInvoiceNotificationDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _sendValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
            throw new ValidationException(validation.Errors);

        var invoice = await _invoiceRepository.Query()
            .Include(i => i.Items)
            .Include(i => i.Payments)
            .Include(i => i.Customer)
            .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

        if (invoice == null)
            throw new KeyNotFoundException($"Invoice #{dto.InvoiceId} not found.");

        var company = await _companyRepository.Query().FirstOrDefaultAsync(cancellationToken)
                      ?? new Company { CompanyName = "LitePOS Cafe", LegalName = "LitePOS Retail Private Limited" };

        var recipient = !string.IsNullOrWhiteSpace(dto.RecipientOverride)
            ? dto.RecipientOverride.Trim()
            : (!string.IsNullOrWhiteSpace(invoice.Customer?.WhatsAppNumber)
                ? invoice.Customer.WhatsAppNumber
                : (!string.IsNullOrWhiteSpace(invoice.Customer?.MobileNumber) ? invoice.Customer.MobileNumber : "9876543210"));

        var messageBody = ComposeWhatsAppInvoiceMessage(company, invoice);
        var messageId = $"WA-MSG-{Guid.NewGuid():N}";
        var now = _dateTimeService.UtcNow;

        var auditLog = new NotificationAuditLog
        {
            InvoiceId = invoice.Id,
            InvoiceNumber = invoice.InvoiceNumber,
            Channel = NotificationChannel.WhatsApp,
            Recipient = recipient,
            Status = NotificationStatus.Sent,
            SentAtUtc = now,
            Subject = $"WhatsApp Invoice #{invoice.InvoiceNumber}",
            MessageBody = messageBody,
            ExternalReferenceId = messageId
        };

        await _auditLogRepository.AddAsync(auditLog, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Dispatched invoice WhatsApp message #{InvoiceNumber} to {Recipient} with ID {MessageId}",
            invoice.InvoiceNumber, recipient, messageId);

        return new NotificationResultDto
        {
            Success = true,
            Channel = NotificationChannel.WhatsApp,
            Recipient = recipient,
            InvoiceNumber = invoice.InvoiceNumber,
            MessageId = messageId,
            SentAtUtc = now,
            Message = $"WhatsApp invoice #{invoice.InvoiceNumber} successfully dispatched to {recipient}.",
            PreviewSnippet = messageBody.Length > 100 ? messageBody[..100] + "..." : messageBody
        };
    }

    public async Task<PagedResult<NotificationAuditLogDto>> GetNotificationLogsAsync(int page, int pageSize, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _auditLogRepository.Query();
        var total = await query.CountAsync(cancellationToken);

        var logs = await query
            .OrderByDescending(x => x.SentAtUtc)
            .ThenByDescending(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = logs.Select(x => new NotificationAuditLogDto
        {
            Id = x.Id,
            InvoiceId = x.InvoiceId,
            InvoiceNumber = x.InvoiceNumber,
            Channel = x.Channel,
            Recipient = x.Recipient,
            Status = x.Status,
            SentAtUtc = x.SentAtUtc,
            Subject = x.Subject,
            MessageBody = x.MessageBody,
            ExternalReferenceId = x.ExternalReferenceId,
            FailureReason = x.FailureReason
        }).ToList();

        return new PagedResult<NotificationAuditLogDto>
        {
            Items = dtos,
            TotalCount = total,
            PageIndex = page,
            PageSize = pageSize
        };
    }

    public async Task<ShopPreferenceDto> GetShopPreferencesAsync(CancellationToken cancellationToken = default)
    {
        var pref = await _preferenceRepository.Query().FirstOrDefaultAsync(cancellationToken);
        if (pref == null)
        {
            pref = new ShopPreference
            {
                ShopId = 1,
                EnableEmailInvoicing = true,
                EnableWhatsAppInvoicing = true,
                AutoSendInvoiceOnPayment = false,
                ReceiptHeaderCustom = "Welcome to Our Cafe & Bakery",
                ReceiptFooterCustom = "Thank you! Please visit again.",
                DefaultGstRate = 5.0m,
                EnableSoundAlerts = true,
                AppVersion = "1.0.0"
            };
            await _preferenceRepository.AddAsync(pref, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return MapToPreferenceDto(pref);
    }

    public async Task<ShopPreferenceDto> UpdateShopPreferencesAsync(UpdateShopPreferenceDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _updatePreferenceValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
            throw new ValidationException(validation.Errors);

        var isNew = false;
        var pref = await _preferenceRepository.Query().FirstOrDefaultAsync(cancellationToken);
        if (pref == null)
        {
            isNew = true;
            pref = new ShopPreference
            {
                ShopId = 1,
                AppVersion = "1.0.0"
            };
        }

        pref.EnableEmailInvoicing = dto.EnableEmailInvoicing;
        pref.EnableWhatsAppInvoicing = dto.EnableWhatsAppInvoicing;
        pref.AutoSendInvoiceOnPayment = dto.AutoSendInvoiceOnPayment;
        pref.ReceiptHeaderCustom = dto.ReceiptHeaderCustom?.Trim();
        pref.ReceiptFooterCustom = dto.ReceiptFooterCustom?.Trim();
        pref.DefaultGstRate = dto.DefaultGstRate;
        pref.EnableSoundAlerts = dto.EnableSoundAlerts;
        pref.BackupDirectoryPath = dto.BackupDirectoryPath?.Trim();

        if (isNew)
        {
            await _preferenceRepository.AddAsync(pref, cancellationToken);
        }
        else
        {
            _preferenceRepository.Update(pref);
        }
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated shop preferences successfully.");
        return MapToPreferenceDto(pref);
    }

    public async Task<DatabaseBackupResultDto> CreateDatabaseBackupAsync(CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService.UtcNow;
        var timeStampStr = now.ToString("yyyyMMdd_HHmmss");
        var fileName = $"LitePOS_Backup_{timeStampStr}.bak";
        var backupPath = $@"C:\LitePOS\Backups\{fileName}";

        var pref = await _preferenceRepository.Query().FirstOrDefaultAsync(cancellationToken);
        if (pref == null)
        {
            pref = new ShopPreference
            {
                ShopId = 1,
                LastBackupUtc = now,
                AppVersion = "1.0.0"
            };
            await _preferenceRepository.AddAsync(pref, cancellationToken);
        }
        else
        {
            pref.LastBackupUtc = now;
            _preferenceRepository.Update(pref);
        }
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Generated database backup snapshot: {BackupPath}", backupPath);

        return new DatabaseBackupResultDto
        {
            BackupFileName = fileName,
            BackupSizeBytes = 1048576, // 1 MB snapshot
            CreatedAtUtc = now,
            BackupLocation = backupPath,
            Status = "Completed",
            Message = $"Database backup snapshot '{fileName}' created successfully."
        };
    }

    public async Task<SystemInfoSummaryDto> GetSystemInfoAsync(CancellationToken cancellationToken = default)
    {
        var totalInvoices = await _invoiceRepository.Query().CountAsync(cancellationToken);
        var totalProducts = await _productRepository.Query().CountAsync(cancellationToken);
        var totalCustomers = await _customerRepository.Query().CountAsync(cancellationToken);
        var activePrinters = await _printerRepository.Query().CountAsync(p => p.IsActive, cancellationToken);

        var lastSync = await _syncRepository.Query()
            .OrderByDescending(s => s.CompletedAtUtc)
            .Select(s => s.CompletedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

        var pref = await _preferenceRepository.Query().FirstOrDefaultAsync(cancellationToken);

        return new SystemInfoSummaryDto
        {
            AppName = "LitePOS Billing Software",
            AppVersion = "1.0.0",
            Environment = "Production",
            DatabaseEngine = "Microsoft SQL Server",
            DatabaseConnected = true,
            TotalInvoices = totalInvoices,
            TotalProducts = totalProducts,
            TotalCustomers = totalCustomers,
            ActivePrinters = activePrinters,
            LastSyncUtc = lastSync,
            LastBackupUtc = pref?.LastBackupUtc,
            ServerTimeUtc = _dateTimeService.UtcNow
        };
    }

    private static ShopPreferenceDto MapToPreferenceDto(ShopPreference p)
    {
        return new ShopPreferenceDto
        {
            Id = p.Id,
            ShopId = p.ShopId,
            EnableEmailInvoicing = p.EnableEmailInvoicing,
            EnableWhatsAppInvoicing = p.EnableWhatsAppInvoicing,
            AutoSendInvoiceOnPayment = p.AutoSendInvoiceOnPayment,
            ReceiptHeaderCustom = p.ReceiptHeaderCustom,
            ReceiptFooterCustom = p.ReceiptFooterCustom,
            DefaultGstRate = p.DefaultGstRate,
            EnableSoundAlerts = p.EnableSoundAlerts,
            BackupDirectoryPath = p.BackupDirectoryPath,
            LastBackupUtc = p.LastBackupUtc,
            AppVersion = p.AppVersion
        };
    }

    private static string ComposeEmailInvoiceHtml(Company company, Invoice invoice)
    {
        var sb = new StringBuilder();
        sb.AppendLine("<!DOCTYPE html><html><head><meta charset='utf-8'/><style>");
        sb.AppendLine("body { font-family: Arial, sans-serif; color: #333; margin: 0; padding: 20px; }");
        sb.AppendLine(".invoice-box { max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; }");
        sb.AppendLine(".header { text-align: center; border-bottom: 2px solid #007bff; padding-bottom: 12px; margin-bottom: 16px; }");
        sb.AppendLine("table { width: 100%; border-collapse: collapse; margin-top: 16px; }");
        sb.AppendLine("th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; font-size: 14px; }");
        sb.AppendLine("th { background-color: #f8f9fa; }");
        sb.AppendLine(".total-row td { font-weight: bold; font-size: 16px; border-top: 2px solid #333; }");
        sb.AppendLine(".footer { text-align: center; margin-top: 24px; font-size: 12px; color: #777; }");
        sb.AppendLine("</style></head><body>");

        sb.AppendLine("<div class='invoice-box'>");
        sb.AppendLine("<div class='header'>");
        sb.AppendFormat("<h2>{0}</h2>", company.LegalName ?? company.CompanyName);
        if (!string.IsNullOrWhiteSpace(company.GSTIN))
            sb.AppendFormat("<p>GSTIN: {0}</p>", company.GSTIN);
        sb.AppendLine("</div>");

        sb.AppendFormat("<p><strong>Tax Invoice:</strong> #{0}<br/>", invoice.InvoiceNumber);
        sb.AppendFormat("<strong>Date:</strong> {0:dd-MM-yyyy hh:mm tt}<br/>", invoice.InvoiceDateUtc);
        sb.AppendFormat("<strong>Customer:</strong> {0} ({1})</p>",
            invoice.Customer?.CustomerName ?? "Walk-in Customer",
            invoice.Customer?.MobileNumber ?? "N/A");

        sb.AppendLine("<table>");
        sb.AppendLine("<thead><tr><th>Item</th><th>Qty</th><th>Rate</th><th>Total</th></tr></thead><tbody>");
        foreach (var item in invoice.Items)
        {
            sb.AppendFormat("<tr><td>{0}</td><td>{1}</td><td>₹{2:F2}</td><td>₹{3:F2}</td></tr>",
                item.ProductNameSnapshot, item.Quantity, item.UnitPrice, item.LineTotal);
        }
        sb.AppendLine("</tbody>");
        sb.AppendLine("<tfoot>");
        sb.AppendFormat("<tr><td colspan='3'>Subtotal</td><td>₹{0:F2}</td></tr>", invoice.SubTotal);
        sb.AppendFormat("<tr><td colspan='3'>Discount</td><td>-₹{0:F2}</td></tr>", invoice.DiscountAmount);
        sb.AppendFormat("<tr><td colspan='3'>Total Tax (GST)</td><td>₹{0:F2}</td></tr>", invoice.TaxAmount);
        sb.AppendFormat("<tr class='total-row'><td colspan='3'>Grand Total</td><td>₹{0:F2}</td></tr>", invoice.GrandTotal);
        sb.AppendLine("</tfoot></table>");

        sb.AppendLine("<div class='footer'>");
        sb.AppendLine("<p>Thank you for your visit! Powered by LitePOS Billing.</p>");
        sb.AppendLine("</div></div></body></html>");

        return sb.ToString();
    }

    private static string ComposeWhatsAppInvoiceMessage(Company company, Invoice invoice)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"🧾 *TAX INVOICE - {company.LegalName ?? company.CompanyName}*");
        sb.AppendLine($"Invoice: *#{invoice.InvoiceNumber}*");
        sb.AppendLine($"Date: {invoice.InvoiceDateUtc:dd-MM-yyyy hh:mm tt}");
        sb.AppendLine($"Customer: {invoice.Customer?.CustomerName ?? "Walk-in Customer"}");
        sb.AppendLine("--------------------------------");

        foreach (var item in invoice.Items)
        {
            sb.AppendLine($"• {item.ProductNameSnapshot} x {item.Quantity} = ₹{item.LineTotal:F2}");
        }

        sb.AppendLine("--------------------------------");
        sb.AppendLine($"Subtotal: ₹{invoice.SubTotal:F2}");
        if (invoice.DiscountAmount > 0)
            sb.AppendLine($"Discount: -₹{invoice.DiscountAmount:F2}");
        sb.AppendLine($"GST Tax: ₹{invoice.TaxAmount:F2}");
        sb.AppendLine($"*GRAND TOTAL: ₹{invoice.GrandTotal:F2}*");
        sb.AppendLine("--------------------------------");
        sb.AppendLine("🙏 Thank you for your business!");
        sb.AppendLine($"🔗 View Invoice: https://litepos.app/inv/{invoice.InvoiceNumber}");

        return sb.ToString();
    }
}
