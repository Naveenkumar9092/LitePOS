using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using BillingPOS.Application.Validators;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using BillingPOS.Infrastructure.Repositories;
using FluentAssertions;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class NotificationServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly INotificationService _notificationService;
    private readonly DateTime _baseDate = new(2026, 11, 14, 11, 0, 0, DateTimeKind.Utc);

    public NotificationServiceTests()
    {
        var mockCurrentUserService = new Mock<ICurrentUserService>();
        mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        var mockDateTimeService = new Mock<IDateTimeService>();
        mockDateTimeService.Setup(s => s.UtcNow).Returns(_baseDate);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_NotificationTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, mockDateTimeService.Object, mockCurrentUserService.Object);

        SeedTestData();

        var auditLogRepo = new GenericRepository<NotificationAuditLog>(_dbContext);
        var prefRepo = new GenericRepository<ShopPreference>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var printerRepo = new GenericRepository<PrinterConfiguration>(_dbContext);
        var syncRepo = new GenericRepository<SyncAuditLog>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<NotificationService>>();

        _notificationService = new NotificationService(
            auditLogRepo,
            prefRepo,
            invoiceRepo,
            companyRepo,
            productRepo,
            customerRepo,
            printerRepo,
            syncRepo,
            unitOfWork,
            mockDateTimeService.Object,
            new SendInvoiceNotificationDtoValidator(),
            new UpdateShopPreferenceDtoValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "LitePOS Cafe",
            LegalName = "LitePOS Retail Private Limited",
            GSTIN = "33AAAAA0000A1Z5",
            MobileNumber = "9876543210",
            Email = "contact@liteposcafe.com",
            IsActive = true
        };

        var customer = new Customer
        {
            Id = 1,
            CustomerName = "Priya Sharma",
            MobileNumber = "9876543201",
            WhatsAppNumber = "9876543201",
            Email = "priya@example.com",
            IsActive = true
        };

        var invoice = new Invoice
        {
            Id = 10,
            InvoiceNumber = "INV-20261114-0010",
            InvoiceDateUtc = _baseDate,
            CustomerId = 1,
            Customer = customer,
            SubTotal = 200.00m,
            DiscountAmount = 0.00m,
            TaxableAmount = 200.00m,
            TaxAmount = 10.00m,
            GrandTotal = 210.00m,
            PaidAmount = 210.00m,
            InvoiceStatus = InvoiceStatus.Active,
            PaymentStatus = PaymentStatus.Paid,
            IsActive = true
        };

        invoice.Items.Add(new InvoiceItem
        {
            Id = 1,
            InvoiceId = 10,
            ProductId = 1,
            ProductNameSnapshot = "Cappuccino",
            Quantity = 2,
            UnitPrice = 100.00m,
            LineTotal = 200.00m,
            TaxPercentage = 5.0m,
            TaxAmount = 10.00m
        });

        invoice.Payments.Add(new Payment
        {
            Id = 1,
            InvoiceId = 10,
            Amount = 210.00m,
            PaymentMode = PaymentMode.UPI,
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = _baseDate
        });

        var product = new Product
        {
            Id = 1,
            CompanyId = 1,
            ProductName = "Cappuccino",
            SellingPrice = 100.00m,
            TaxPercentage = 5.0m,
            IsAvailable = true,
            IsActive = true
        };

        var printer = new PrinterConfiguration
        {
            Id = 1,
            PrinterName = "Counter 80mm",
            IsDefault = true,
            IsActive = true
        };

        var syncLog = new SyncAuditLog
        {
            Id = 1,
            DeviceId = "POS-TERM-01",
            SyncType = "Full",
            Status = "Success",
            StartedAtUtc = _baseDate.AddHours(-1),
            CompletedAtUtc = _baseDate.AddHours(-1).AddSeconds(2)
        };

        _dbContext.Companies.Add(company);
        _dbContext.Customers.Add(customer);
        _dbContext.Invoices.Add(invoice);
        _dbContext.Products.Add(product);
        _dbContext.PrinterConfigurations.Add(printer);
        _dbContext.SyncAuditLogs.Add(syncLog);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task SendInvoiceEmailAsync_ValidInvoice_CreatesAuditLogAndReturnsSuccess()
    {
        var dto = new SendInvoiceNotificationDto
        {
            InvoiceId = 10,
            Channel = NotificationChannel.Email
        };

        var result = await _notificationService.SendInvoiceEmailAsync(dto);

        result.Should().NotBeNull();
        result.Success.Should().BeTrue();
        result.Channel.Should().Be(NotificationChannel.Email);
        result.Recipient.Should().Be("priya@example.com");
        result.InvoiceNumber.Should().Be("INV-20261114-0010");
        result.MessageId.Should().StartWith("EMAIL-MSG-");

        var auditLog = await _dbContext.NotificationAuditLogs.FirstOrDefaultAsync(x => x.InvoiceId == 10);
        auditLog.Should().NotBeNull();
        auditLog!.Channel.Should().Be(NotificationChannel.Email);
        auditLog.Status.Should().Be(NotificationStatus.Sent);
        auditLog.MessageBody.Should().Contain("Cappuccino");
    }

    [Fact]
    public async Task SendInvoiceEmailAsync_NonExistingInvoice_ThrowsKeyNotFoundException()
    {
        var dto = new SendInvoiceNotificationDto
        {
            InvoiceId = 999,
            Channel = NotificationChannel.Email
        };

        var act = () => _notificationService.SendInvoiceEmailAsync(dto);
        await act.Should().ThrowAsync<KeyNotFoundException>();
    }

    [Fact]
    public async Task SendInvoiceEmailAsync_WithRecipientOverride_DispatchesToSpecifiedEmail()
    {
        var dto = new SendInvoiceNotificationDto
        {
            InvoiceId = 10,
            Channel = NotificationChannel.Email,
            RecipientOverride = "custom.recipient@company.org"
        };

        var result = await _notificationService.SendInvoiceEmailAsync(dto);

        result.Success.Should().BeTrue();
        result.Recipient.Should().Be("custom.recipient@company.org");
    }

    [Fact]
    public async Task SendInvoiceWhatsAppAsync_ValidInvoice_CreatesAuditLogWithFormattedMessage()
    {
        var dto = new SendInvoiceNotificationDto
        {
            InvoiceId = 10,
            Channel = NotificationChannel.WhatsApp
        };

        var result = await _notificationService.SendInvoiceWhatsAppAsync(dto);

        result.Should().NotBeNull();
        result.Success.Should().BeTrue();
        result.Channel.Should().Be(NotificationChannel.WhatsApp);
        result.Recipient.Should().Be("9876543201");
        result.MessageId.Should().StartWith("WA-MSG-");

        var auditLog = await _dbContext.NotificationAuditLogs.FirstOrDefaultAsync(x => x.Channel == NotificationChannel.WhatsApp);
        auditLog.Should().NotBeNull();
        auditLog!.Status.Should().Be(NotificationStatus.Sent);
        auditLog.MessageBody.Should().Contain("TAX INVOICE");
        auditLog.MessageBody.Should().Contain("Cappuccino");
    }

    [Fact]
    public async Task SendInvoiceWhatsAppAsync_NonExistingInvoice_ThrowsKeyNotFoundException()
    {
        var dto = new SendInvoiceNotificationDto
        {
            InvoiceId = 999,
            Channel = NotificationChannel.WhatsApp
        };

        var act = () => _notificationService.SendInvoiceWhatsAppAsync(dto);
        await act.Should().ThrowAsync<KeyNotFoundException>();
    }

    [Fact]
    public async Task GetNotificationLogsAsync_ReturnsPagedLogs_OrderedByDate()
    {
        _dbContext.NotificationAuditLogs.AddRange(
            new NotificationAuditLog { InvoiceId = 1, InvoiceNumber = "INV-1", Channel = NotificationChannel.Email, Recipient = "user1@test.com", Status = NotificationStatus.Sent, SentAtUtc = _baseDate.AddMinutes(-10), MessageBody = "Body 1" },
            new NotificationAuditLog { InvoiceId = 2, InvoiceNumber = "INV-2", Channel = NotificationChannel.WhatsApp, Recipient = "9876543202", Status = NotificationStatus.Sent, SentAtUtc = _baseDate.AddMinutes(-5), MessageBody = "Body 2" }
        );
        await _dbContext.SaveChangesAsync();

        var result = await _notificationService.GetNotificationLogsAsync(1, 10);

        result.TotalCount.Should().Be(2);
        result.Items.Count.Should().Be(2);
        result.Items[0].InvoiceNumber.Should().Be("INV-2");
    }

    [Fact]
    public async Task GetShopPreferencesAsync_WhenNoneExists_CreatesAndReturnsDefault()
    {
        var pref = await _notificationService.GetShopPreferencesAsync();

        pref.Should().NotBeNull();
        pref.ShopId.Should().Be(1);
        pref.EnableEmailInvoicing.Should().BeTrue();
        pref.EnableWhatsAppInvoicing.Should().BeTrue();
        pref.DefaultGstRate.Should().Be(5.0m);
    }

    [Fact]
    public async Task UpdateShopPreferencesAsync_ValidDto_UpdatesAndPersistsPreferences()
    {
        var updateDto = new UpdateShopPreferenceDto
        {
            EnableEmailInvoicing = true,
            EnableWhatsAppInvoicing = false,
            AutoSendInvoiceOnPayment = true,
            ReceiptHeaderCustom = "Custom Header Text",
            ReceiptFooterCustom = "Custom Footer Greeting",
            DefaultGstRate = 18.0m,
            EnableSoundAlerts = false,
            BackupDirectoryPath = @"D:\Backups"
        };

        var updated = await _notificationService.UpdateShopPreferencesAsync(updateDto);

        updated.EnableWhatsAppInvoicing.Should().BeFalse();
        updated.AutoSendInvoiceOnPayment.Should().BeTrue();
        updated.ReceiptHeaderCustom.Should().Be("Custom Header Text");
        updated.DefaultGstRate.Should().Be(18.0m);
        updated.BackupDirectoryPath.Should().Be(@"D:\Backups");
    }

    [Fact]
    public async Task UpdateShopPreferencesAsync_InvalidGstRate_ThrowsValidationException()
    {
        var updateDto = new UpdateShopPreferenceDto
        {
            DefaultGstRate = 150.0m // Invalid > 100%
        };

        var act = () => _notificationService.UpdateShopPreferencesAsync(updateDto);
        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task CreateDatabaseBackupAsync_ReturnsBackupResult_AndUpdatesLastBackupUtc()
    {
        var result = await _notificationService.CreateDatabaseBackupAsync();

        result.Should().NotBeNull();
        result.Status.Should().Be("Completed");
        result.BackupFileName.Should().StartWith("LitePOS_Backup_");
        result.BackupSizeBytes.Should().BeGreaterThan(0);

        var pref = await _dbContext.ShopPreferences.FirstOrDefaultAsync();
        pref.Should().NotBeNull();
        pref!.LastBackupUtc.Should().Be(_baseDate);
    }

    [Fact]
    public async Task GetSystemInfoAsync_ReturnsCorrectRecordCountsAndServerTime()
    {
        var sysInfo = await _notificationService.GetSystemInfoAsync();

        sysInfo.Should().NotBeNull();
        sysInfo.AppName.Should().Be("LitePOS Billing Software");
        sysInfo.TotalInvoices.Should().Be(1);
        sysInfo.TotalProducts.Should().Be(1);
        sysInfo.TotalCustomers.Should().Be(1);
        sysInfo.ActivePrinters.Should().Be(1);
        sysInfo.DatabaseConnected.Should().BeTrue();
        sysInfo.ServerTimeUtc.Should().Be(_baseDate);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        GC.SuppressFinalize(this);
    }
}
