using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using BillingPOS.Infrastructure.Repositories;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class SyncServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly ISyncService _syncService;
    private readonly DateTime _baseDate = new(2026, 11, 13, 12, 0, 0, DateTimeKind.Utc);

    public SyncServiceTests()
    {
        var mockCurrentUserService = new Mock<ICurrentUserService>();
        mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        var mockDateTimeService = new Mock<IDateTimeService>();
        mockDateTimeService.Setup(s => s.UtcNow).Returns(_baseDate);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_SyncTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, mockDateTimeService.Object, mockCurrentUserService.Object);

        SeedTestData();

        var deviceRepo = new GenericRepository<Device, string>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var categoryRepo = new GenericRepository<Category>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var taxRepo = new GenericRepository<Tax>(_dbContext);
        var hsnSacRepo = new GenericRepository<HsnSac>(_dbContext);
        var gstConfigRepo = new GenericRepository<GstConfiguration>(_dbContext);
        var syncAuditLogRepo = new GenericRepository<SyncAuditLog>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var currentUserServiceMock = new Mock<ICurrentUserService>();
        currentUserServiceMock.Setup(u => u.CompanyId).Returns(1);
        var loggerMock = new Mock<ILogger<SyncService>>();

        _syncService = new SyncService(
            deviceRepo,
            invoiceRepo,
            customerRepo,
            companyRepo,
            categoryRepo,
            productRepo,
            taxRepo,
            hsnSacRepo,
            gstConfigRepo,
            syncAuditLogRepo,
            unitOfWork,
            currentUserServiceMock.Object,
            mockDateTimeService.Object,
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "Cafe Bliss",
            LegalName = "Cafe Bliss Private Limited",
            BusinessType = BusinessType.Cafe,
            GSTIN = "33AAAAA0000A1Z5",
            Shop = new Shop { Id = 1, CompanyId = 1, ShopName = "Main Branch", IsActive = true }
        };

        var catBeverages = new Category { Id = 1, CategoryName = "Beverages", IsActive = true, DisplayOrder = 1 };
        var catSnacks = new Category { Id = 2, CategoryName = "Snacks", IsActive = true, DisplayOrder = 2 };

        var prodCappuccino = new Product
        {
            Id = 1,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Cappuccino",
            SellingPrice = 120.0m,
            TaxPercentage = 5.0m,
            HSNCode = "996331",
            IsAvailable = true,
            IsActive = true,
            Category = catBeverages
        };

        var tax5 = new Tax
        {
            Id = 1,
            TaxName = "GST 5%",
            RatePercentage = 5.0m,
            CgstPercentage = 2.5m,
            SgstPercentage = 2.5m,
            IsDefault = true,
            IsActive = true
        };

        var hsn = new HsnSac
        {
            Id = 1,
            Code = "996331",
            Description = "Cafe and Food Services",
            DefaultGstRate = 5.0m,
            IsActive = true
        };

        var gstConfig = new GstConfiguration
        {
            Id = 1,
            GSTIN = "33AAAAA0000A1Z5",
            LegalName = "Cafe Bliss Private Limited",
            TradeName = "Cafe Bliss",
            StateName = "Tamil Nadu",
            StateCode = "33",
            IsActive = true
        };

        _dbContext.Companies.Add(company);
        _dbContext.Categories.AddRange(catBeverages, catSnacks);
        _dbContext.Products.Add(prodCappuccino);
        _dbContext.Taxes.Add(tax5);
        _dbContext.HsnSacs.Add(hsn);
        _dbContext.GstConfigurations.Add(gstConfig);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task RegisterDeviceAsync_RegistersNewDeviceSuccessfully()
    {
        var dto = new RegisterDeviceDto("POS-TERM-01", "Counter 1 Tablet", "1.0.0", true);

        var result = await _syncService.RegisterDeviceAsync(dto);

        result.DeviceId.Should().Be("POS-TERM-01");
        result.DeviceName.Should().Be("Counter 1 Tablet");
        result.IsOnline.Should().BeTrue();

        var dbDevice = await _dbContext.Devices.FindAsync("POS-TERM-01");
        dbDevice.Should().NotBeNull();
        dbDevice!.DeviceName.Should().Be("Counter 1 Tablet");
    }

    [Fact]
    public async Task RegisterDeviceAsync_UpdatesExistingDeviceHeartbeat()
    {
        await _syncService.RegisterDeviceAsync(new RegisterDeviceDto("POS-TERM-01", "Counter 1 Tablet", "1.0.0", true));

        var updated = await _syncService.RegisterDeviceAsync(new RegisterDeviceDto("POS-TERM-01", "Counter 1 Desktop", "1.1.0", true));

        updated.DeviceName.Should().Be("Counter 1 Desktop");
        updated.AppVersion.Should().Be("1.1.0");

        var dbDevice = await _dbContext.Devices.FindAsync("POS-TERM-01");
        dbDevice!.DeviceName.Should().Be("Counter 1 Desktop");
    }

    [Fact]
    public async Task GetDeviceStatusAsync_ReturnsStatusWhenFound()
    {
        await _syncService.RegisterDeviceAsync(new RegisterDeviceDto("POS-TERM-02", "Counter 2", "1.0.0", true));

        var status = await _syncService.GetDeviceStatusAsync("POS-TERM-02");

        status.Should().NotBeNull();
        status!.DeviceId.Should().Be("POS-TERM-02");
    }

    [Fact]
    public async Task GetDeviceStatusAsync_ReturnsNullWhenNotFound()
    {
        var status = await _syncService.GetDeviceStatusAsync("NON-EXISTENT-DEVICE");
        status.Should().BeNull();
    }

    [Fact]
    public async Task PushSyncBatchAsync_SyncsOfflineCustomersAndGeneratesIds()
    {
        var custGuid = Guid.NewGuid();
        var pushReq = new SyncPushRequestDto(
            DeviceId: "POS-TERM-01",
            AppVersion: "1.0.0",
            ClientSyncTimestampUtc: _baseDate,
            Customers: new List<SyncCustomerPushDto>
            {
                new(custGuid, "Anand Kumar", "9876543299", "9876543299", "anand@test.com", "Adyar, Chennai", null, true, true, _baseDate)
            },
            Invoices: new List<SyncInvoicePushDto>());

        var result = await _syncService.PushSyncBatchAsync(pushReq);

        result.TotalProcessed.Should().Be(1);
        result.TotalFailed.Should().Be(0);
        result.SyncedCustomers.Should().HaveCount(1);
        result.SyncedCustomers[0].ClientGuid.Should().Be(custGuid);
        result.SyncedCustomers[0].WasAlreadySynced.Should().BeFalse();

        var dbCust = await _dbContext.Customers.FirstOrDefaultAsync(c => c.CustomerGuid == custGuid);
        dbCust.Should().NotBeNull();
        dbCust!.CustomerName.Should().Be("Anand Kumar");
    }

    [Fact]
    public async Task PushSyncBatchAsync_IdempotentlyRecognizesExistingCustomerGuid()
    {
        var custGuid = Guid.NewGuid();
        var pushReq = new SyncPushRequestDto(
            DeviceId: "POS-TERM-01",
            AppVersion: "1.0.0",
            ClientSyncTimestampUtc: _baseDate,
            Customers: new List<SyncCustomerPushDto>
            {
                new(custGuid, "Ravi Ashwin", "9876543288")
            },
            Invoices: new List<SyncInvoicePushDto>());

        // First push
        await _syncService.PushSyncBatchAsync(pushReq);

        // Duplicate push with same GUID
        var secondResult = await _syncService.PushSyncBatchAsync(pushReq);

        secondResult.TotalProcessed.Should().Be(1);
        secondResult.SyncedCustomers[0].WasAlreadySynced.Should().BeTrue();
        (await _dbContext.Customers.CountAsync(c => c.CustomerGuid == custGuid)).Should().Be(1);
    }

    [Fact]
    public async Task PushSyncBatchAsync_SyncsOfflineInvoicesWithItemsAndPayments()
    {
        var invGuid = Guid.NewGuid();
        var payGuid = Guid.NewGuid();

        var invoiceDto = new SyncInvoicePushDto(
            InvoiceGuid: invGuid,
            InvoiceNumber: "OFF-INV-001",
            CustomerId: null,
            CustomerGuid: null,
            CashierId: 1,
            InvoiceDateUtc: _baseDate,
            SubTotal: 120.0m,
            DiscountAmount: 0.0m,
            TaxableAmount: 114.29m,
            TaxAmount: 5.71m,
            GrandTotal: 120.0m,
            PaidAmount: 120.0m,
            BalanceAmount: 0.0m,
            PaymentStatus: PaymentStatus.Paid,
            InvoiceStatus: InvoiceStatus.Active,
            Items: new List<SyncInvoiceItemPushDto>
            {
                new(1, "Cappuccino", 120.0m, 1, 0.0m, 5.0m, 5.71m, 120.0m)
            },
            Payments: new List<SyncPaymentPushDto>
            {
                new(payGuid, PaymentMode.Cash, 120.0m, null, PaymentStatus.Paid, _baseDate)
            });

        var pushReq = new SyncPushRequestDto("POS-TERM-01", "1.0.0", _baseDate, new List<SyncCustomerPushDto>(), new List<SyncInvoicePushDto> { invoiceDto });

        var result = await _syncService.PushSyncBatchAsync(pushReq);

        result.TotalProcessed.Should().Be(1);
        result.SyncedInvoices.Should().HaveCount(1);
        result.SyncedInvoices[0].ClientGuid.Should().Be(invGuid);
        result.SyncedInvoices[0].WasAlreadySynced.Should().BeFalse();

        var dbInvoice = await _dbContext.Invoices.Include(i => i.Items).Include(i => i.Payments).FirstOrDefaultAsync(i => i.InvoiceGuid == invGuid);
        dbInvoice.Should().NotBeNull();
        dbInvoice!.InvoiceNumber.Should().Be("OFF-INV-001");
        dbInvoice.Items.Should().HaveCount(1);
        dbInvoice.Payments.Should().HaveCount(1);
    }

    [Fact]
    public async Task PushSyncBatchAsync_IdempotentlyRecognizesExistingInvoiceGuid()
    {
        var invGuid = Guid.NewGuid();
        var invoiceDto = new SyncInvoicePushDto(
            InvoiceGuid: invGuid,
            InvoiceNumber: "OFF-INV-002",
            CustomerId: null,
            CustomerGuid: null,
            CashierId: 1,
            InvoiceDateUtc: _baseDate,
            SubTotal: 200.0m,
            DiscountAmount: 0.0m,
            TaxableAmount: 200.0m,
            TaxAmount: 10.0m,
            GrandTotal: 210.0m,
            PaidAmount: 210.0m,
            BalanceAmount: 0.0m,
            PaymentStatus: PaymentStatus.Paid,
            InvoiceStatus: InvoiceStatus.Active,
            Items: new List<SyncInvoiceItemPushDto>(),
            Payments: new List<SyncPaymentPushDto>());

        var pushReq = new SyncPushRequestDto("POS-TERM-01", "1.0.0", _baseDate, new List<SyncCustomerPushDto>(), new List<SyncInvoicePushDto> { invoiceDto });

        await _syncService.PushSyncBatchAsync(pushReq);
        var secondResult = await _syncService.PushSyncBatchAsync(pushReq);

        secondResult.SyncedInvoices[0].WasAlreadySynced.Should().BeTrue();
        (await _dbContext.Invoices.CountAsync(i => i.InvoiceGuid == invGuid)).Should().Be(1);
    }

    [Fact]
    public async Task PullSyncCatalogAsync_DownsyncsCategoriesProductsTaxesAndConfig()
    {
        var req = new SyncPullRequestDto("POS-TERM-01", null);

        var result = await _syncService.PullSyncCatalogAsync(req);

        result.Company.Should().NotBeNull();
        result.Company!.CompanyName.Should().Be("Cafe Bliss");
        result.Categories.Should().HaveCount(2);
        result.Products.Should().HaveCount(1);
        result.Taxes.Should().HaveCount(1);
        result.HsnSacs.Should().HaveCount(1);
        result.GstConfiguration.Should().NotBeNull();
        result.TotalRecords.Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetSyncHistoryAsync_ReturnsRecentAuditLogs()
    {
        var req = new SyncPullRequestDto("POS-TERM-01", null);
        await _syncService.PullSyncCatalogAsync(req);

        var history = await _syncService.GetSyncHistoryAsync("POS-TERM-01", 10);

        history.Should().NotBeEmpty();
        history[0].DeviceId.Should().Be("POS-TERM-01");
        history[0].Status.Should().Be("Success");
        history[0].SyncType.Should().Be("Pull");
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

