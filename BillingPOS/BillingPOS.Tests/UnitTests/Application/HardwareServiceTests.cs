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
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class HardwareServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IHardwareService _hardwareService;
    private readonly DateTime _baseDate = new(2026, 11, 14, 10, 0, 0, DateTimeKind.Utc);

    public HardwareServiceTests()
    {
        var mockCurrentUserService = new Mock<ICurrentUserService>();
        mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        var mockDateTimeService = new Mock<IDateTimeService>();
        mockDateTimeService.Setup(s => s.UtcNow).Returns(_baseDate);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_HardwareTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, mockDateTimeService.Object, mockCurrentUserService.Object);

        SeedTestData();

        var printerRepo = new GenericRepository<PrinterConfiguration>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var gstConfigRepo = new GenericRepository<GstConfiguration>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<HardwareService>>();

        _hardwareService = new HardwareService(
            printerRepo,
            invoiceRepo,
            companyRepo,
            gstConfigRepo,
            unitOfWork,
            mockDateTimeService.Object,
            new CreatePrinterConfigurationValidator(),
            new UpdatePrinterConfigurationValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "Cafe Bliss",
            LegalName = "Cafe Bliss Pvt Ltd",
            BusinessType = BusinessType.Cafe,
            GSTIN = "33AAAAA0000A1Z5",
            Shop = new Shop { Id = 1, CompanyId = 1, ShopName = "Main Branch", AddressLine1 = "124 Anna Salai, Chennai", ContactNumber = "9876543210", IsActive = true }
        };

        var gstConfig = new GstConfiguration
        {
            Id = 1,
            GSTIN = "33AAAAA0000A1Z5",
            TradeName = "Cafe Bliss",
            LegalName = "Cafe Bliss Pvt Ltd",
            StateName = "Tamil Nadu",
            StateCode = "33",
            IsActive = true
        };

        var printer1 = new PrinterConfiguration
        {
            Id = 1,
            CompanyId = 1,
            ShopId = 1,
            PrinterName = "Primary 80mm Network Printer",
            ConnectionType = PrinterConnectionType.Network,
            IpAddress = "192.168.1.100",
            Port = 9100,
            PaperSize = PrinterPaperSize.Mm80,
            CharacterColumns = 48,
            AutoCutReceipt = true,
            OpenCashDrawer = true,
            PrintQrCode = true,
            IsDefault = true,
            IsActive = true
        };

        var printer2 = new PrinterConfiguration
        {
            Id = 2,
            CompanyId = 1,
            ShopId = 1,
            PrinterName = "Dessert Counter 58mm USB",
            ConnectionType = PrinterConnectionType.USB,
            UsbDeviceName = "POS-58",
            PaperSize = PrinterPaperSize.Mm58,
            CharacterColumns = 32,
            AutoCutReceipt = true,
            OpenCashDrawer = false,
            PrintQrCode = false,
            IsDefault = false,
            IsActive = true
        };

        var cashier = new User { Id = 1, CompanyId = 1, ShopId = 1, FullName = "Arun Kumar", Username = "cashier" };
        var customer = new Customer { Id = 1, CustomerName = "Karthik", MobileNumber = "9876543201" };

        var invoice = new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CompanyId = 1,
            ShopId = 1,
            CashierId = 1,
            Cashier = cashier,
            CustomerId = 1,
            Customer = customer,
            Company = company,
            Shop = company.Shop!,
            InvoiceDateUtc = _baseDate,
            SubTotal = 200.0m,
            DiscountAmount = 10.0m,
            TaxableAmount = 190.0m,
            TaxAmount = 9.5m,
            GrandTotal = 199.5m,
            PaidAmount = 200.0m,
            BalanceAmount = 0.0m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };

        invoice.Items.Add(new InvoiceItem
        {
            Id = 1,
            InvoiceId = 1,
            ProductId = 1,
            ProductNameSnapshot = "Hazelnut Cold Coffee",
            UnitPrice = 100.0m,
            Quantity = 2,
            DiscountAmount = 10.0m,
            TaxPercentage = 5.0m,
            TaxAmount = 9.5m,
            LineTotal = 199.5m
        });

        invoice.Payments.Add(new Payment
        {
            Id = 1,
            InvoiceId = 1,
            PaymentMode = PaymentMode.UPI,
            Amount = 199.5m,
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = _baseDate
        });

        _dbContext.Companies.Add(company);
        _dbContext.GstConfigurations.Add(gstConfig);
        _dbContext.PrinterConfigurations.AddRange(printer1, printer2);
        _dbContext.Users.Add(cashier);
        _dbContext.Customers.Add(customer);
        _dbContext.Invoices.Add(invoice);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetPrintersAsync_ReturnsActivePrintersOrderedByDefault()
    {
        var result = await _hardwareService.GetPrintersAsync();

        result.Should().HaveCount(2);
        result[0].IsDefault.Should().BeTrue();
        result[0].PrinterName.Should().Be("Primary 80mm Network Printer");
    }

    [Fact]
    public async Task GetPrinterByIdAsync_ReturnsPrinterWhenFound()
    {
        var result = await _hardwareService.GetPrinterByIdAsync(1);

        result.Should().NotBeNull();
        result!.PrinterName.Should().Be("Primary 80mm Network Printer");
        result.PaperSize.Should().Be(PrinterPaperSize.Mm80);
    }

    [Fact]
    public async Task GetDefaultPrinterAsync_ReturnsDefaultPrinter()
    {
        var result = await _hardwareService.GetDefaultPrinterAsync();

        result.Should().NotBeNull();
        result.IsDefault.Should().BeTrue();
        result.Id.Should().Be(1);
    }

    [Fact]
    public async Task CreatePrinterAsync_ValidNetworkPrinter_CreatesAndSaves()
    {
        var dto = new CreatePrinterConfigurationDto(
            PrinterName: "New Kitchen Bluetooth Printer",
            ConnectionType: PrinterConnectionType.Bluetooth,
            BluetoothMacAddress: "00:11:22:33:44:55",
            PaperSize: PrinterPaperSize.Mm58,
            IsDefault: false);

        var result = await _hardwareService.CreatePrinterAsync(dto);

        result.Id.Should().BeGreaterThan(0);
        result.PrinterName.Should().Be("New Kitchen Bluetooth Printer");
        result.CharacterColumns.Should().Be(32); // auto defaulted for 58mm

        var dbEntity = await _dbContext.PrinterConfigurations.FindAsync(result.Id);
        dbEntity.Should().NotBeNull();
    }

    [Fact]
    public async Task CreatePrinterAsync_WhenIsDefault_ClearsOtherDefaults()
    {
        var dto = new CreatePrinterConfigurationDto(
            PrinterName: "New Default Printer",
            ConnectionType: PrinterConnectionType.Network,
            IpAddress: "192.168.1.150",
            Port: 9100,
            PaperSize: PrinterPaperSize.Mm80,
            IsDefault: true);

        var result = await _hardwareService.CreatePrinterAsync(dto);

        result.IsDefault.Should().BeTrue();
        var oldDefault = await _dbContext.PrinterConfigurations.FindAsync(1L);
        oldDefault!.IsDefault.Should().BeFalse();
    }

    [Fact]
    public async Task UpdatePrinterAsync_UpdatesFieldsProperly()
    {
        var dto = new UpdatePrinterConfigurationDto(
            PrinterName: "Updated 80mm Printer",
            ConnectionType: PrinterConnectionType.Network,
            IpAddress: "192.168.1.200",
            Port: 9100,
            PaperSize: PrinterPaperSize.Mm80,
            IsDefault: true);

        var result = await _hardwareService.UpdatePrinterAsync(1, dto);

        result.PrinterName.Should().Be("Updated 80mm Printer");
        result.IpAddress.Should().Be("192.168.1.200");
    }

    [Fact]
    public async Task DeletePrinterAsync_DeactivatesPrinter()
    {
        var success = await _hardwareService.DeletePrinterAsync(2);

        success.Should().BeTrue();
        var printer = await _dbContext.PrinterConfigurations.FindAsync(2L);
        printer!.IsActive.Should().BeFalse();
    }

    [Fact]
    public async Task SetDefaultPrinterAsync_UpdatesDefaultStatus()
    {
        var result = await _hardwareService.SetDefaultPrinterAsync(2);

        result.IsDefault.Should().BeTrue();
        var printer1 = await _dbContext.PrinterConfigurations.FindAsync(1L);
        printer1!.IsDefault.Should().BeFalse();
    }

    [Fact]
    public void GenerateOpenCashDrawerCommand_ReturnsStandardEscPosPulse()
    {
        var cmd = _hardwareService.GenerateOpenCashDrawerCommand();

        cmd.CommandName.Should().Contain("Cash Drawer");
        cmd.Base64EscPosBytes.Should().NotBeNullOrEmpty();
        cmd.HexString.Should().Be("1B 70 00 19 FA");
    }

    [Fact]
    public async Task GenerateTestPrintAsync_ProducesValidEscPosBytesAndPreview()
    {
        var result = await _hardwareService.GenerateTestPrintAsync(1);

        result.PrinterName.Should().Be("Primary 80mm Network Printer");
        result.ByteCount.Should().BeGreaterThan(50);
        result.Base64EscPosBytes.Should().NotBeNullOrEmpty();
        result.PlainTextPreview.Should().Contain("HARDWARE TEST");
        result.PlainTextPreview.Should().Contain("PRINTER WORKING PERFECTLY");
    }

    [Fact]
    public async Task GenerateInvoiceReceiptEscPosAsync_Formats80mmReceiptWithItemsAndGst()
    {
        var result = await _hardwareService.GenerateInvoiceReceiptEscPosAsync(1, 1);

        result.InvoiceId.Should().Be(1);
        result.InvoiceNumber.Should().Be("INV-2026-0001");
        result.ByteCount.Should().BeGreaterThan(100);
        result.Base64EscPosBytes.Should().NotBeNullOrEmpty();

        var preview = result.PlainTextPreview;
        preview.Should().Contain("Cafe Bliss");
        preview.Should().Contain("INV-2026-0001");
        preview.Should().Contain("Hazelnut Cold Coffee");
        preview.Should().Contain("GRAND TOTAL");
        preview.Should().Contain("199.50");
        preview.Should().Contain("CGST");
        preview.Should().Contain("SGST");
        preview.Should().Contain("upi://pay");
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

