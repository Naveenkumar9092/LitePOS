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

public class GstServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IGstService _gstService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public GstServiceTests()
    {
        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        _mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_GstTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, _mockDateTimeService.Object, _mockCurrentUserService.Object);

        SeedTestData();

        var taxRepo = new GenericRepository<Tax>(_dbContext);
        var hsnRepo = new GenericRepository<HsnSac>(_dbContext);
        var gstConfigRepo = new GenericRepository<GstConfiguration>(_dbContext);
        var creditNoteRepo = new GenericRepository<CreditNote>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<GstService>>();

        _gstService = new GstService(
            taxRepo,
            hsnRepo,
            gstConfigRepo,
            creditNoteRepo,
            invoiceRepo,
            productRepo,
            unitOfWork,
            _mockDateTimeService.Object,
            _mockCurrentUserService.Object,
            new CreateTaxValidator(),
            new UpdateTaxValidator(),
            new CreateHsnSacValidator(),
            new UpdateGstConfigurationValidator(),
            new CreateCreditNoteValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        _dbContext.Taxes.AddRange(
            new Tax { Id = 1, TaxName = "Exempt 0%", RatePercentage = 0m, CgstPercentage = 0m, SgstPercentage = 0m, IgstPercentage = 0m, IsActive = true, IsDefault = false },
            new Tax { Id = 2, TaxName = "GST 5%", RatePercentage = 5m, CgstPercentage = 2.5m, SgstPercentage = 2.5m, IgstPercentage = 5m, IsActive = true, IsDefault = true },
            new Tax { Id = 3, TaxName = "GST 12%", RatePercentage = 12m, CgstPercentage = 6m, SgstPercentage = 6m, IgstPercentage = 12m, IsActive = true, IsDefault = false },
            new Tax { Id = 4, TaxName = "GST 18%", RatePercentage = 18m, CgstPercentage = 9m, SgstPercentage = 9m, IgstPercentage = 18m, IsActive = true, IsDefault = false },
            new Tax { Id = 5, TaxName = "GST 28%", RatePercentage = 28m, CgstPercentage = 14m, SgstPercentage = 14m, IgstPercentage = 28m, IsActive = true, IsDefault = false }
        );

        _dbContext.HsnSacs.AddRange(
            new HsnSac { Id = 1, Code = "2106", Description = "Food preparations n.e.c (Sweets, snacks)", Type = "HSN", DefaultGstRate = 5m, IsActive = true },
            new HsnSac { Id = 2, Code = "2202", Description = "Waters and flavoured beverages", Type = "HSN", DefaultGstRate = 18m, IsActive = true }
        );

        _dbContext.GstConfigurations.Add(new GstConfiguration
        {
            Id = 1,
            CompanyId = 1,
            ShopId = 1,
            GSTIN = "33AAAAA0000A1Z5",
            LegalName = "LitePOS Food Services Pvt Ltd",
            TradeName = "LitePOS Cafe",
            StateName = "Tamil Nadu",
            StateCode = "33",
            IsCompositionScheme = false,
            DefaultPricingIsTaxInclusive = true
        });

        var product1 = new Product
        {
            Id = 1,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Espresso Coffee",
            SellingPrice = 100m,
            TaxPercentage = 5m,
            HSNCode = "2106",
            IsAvailable = true
        };

        var product2 = new Product
        {
            Id = 2,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Bottled Mineral Water",
            SellingPrice = 50m,
            TaxPercentage = 18m,
            HSNCode = "2202",
            IsAvailable = true
        };

        _dbContext.Products.AddRange(product1, product2);

        var customerB2b = new Customer
        {
            Id = 1,
            CustomerName = "Corporate Client Bangalore",
            MobileNumber = "9876543210",
            GSTIN = "29BBBBB1111B1Z2" // Karnataka (Inter-state from 33 TN)
        };

        var customerB2c = new Customer
        {
            Id = 2,
            CustomerName = "Walk-in Retail Customer",
            MobileNumber = "9123456780",
            GSTIN = null
        };

        _dbContext.Customers.AddRange(customerB2b, customerB2c);

        var invB2c = new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-202611-0001",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 2,
            CashierId = 1,
            InvoiceDateUtc = _fixedNow.AddHours(-2),
            SubTotal = 200m,
            TaxableAmount = 190.48m,
            TaxAmount = 9.52m,
            GrandTotal = 200m,
            PaidAmount = 200m,
            BalanceAmount = 0m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };
        invB2c.Items.Add(new InvoiceItem
        {
            Id = 1,
            InvoiceId = 1,
            ProductId = 1,
            ProductNameSnapshot = "Espresso Coffee",
            UnitPrice = 100m,
            Quantity = 2,
            TaxPercentage = 5m,
            TaxAmount = 9.52m,
            LineTotal = 200m
        });

        var invB2b = new Invoice
        {
            Id = 2,
            InvoiceNumber = "INV-202611-0002",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            Customer = customerB2b,
            CashierId = 1,
            InvoiceDateUtc = _fixedNow.AddHours(-1),
            SubTotal = 500m,
            TaxableAmount = 476.19m,
            TaxAmount = 23.81m,
            GrandTotal = 500m,
            PaidAmount = 500m,
            BalanceAmount = 0m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };
        invB2b.Items.Add(new InvoiceItem
        {
            Id = 2,
            InvoiceId = 2,
            ProductId = 1,
            ProductNameSnapshot = "Espresso Coffee",
            UnitPrice = 100m,
            Quantity = 5,
            TaxPercentage = 5m,
            TaxAmount = 23.81m,
            LineTotal = 500m
        });

        _dbContext.Invoices.AddRange(invB2c, invB2b);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetTaxesAsync_ReturnsAllConfiguredTaxes()
    {
        var taxes = await _gstService.GetTaxesAsync();

        taxes.Should().NotBeNull();
        taxes.Count.Should().Be(5);
        taxes.Should().Contain(t => t.RatePercentage == 5m && t.CgstPercentage == 2.5m && t.SgstPercentage == 2.5m);
    }

    [Fact]
    public async Task CreateTaxAsync_WithValidData_CalculatesSplitTaxesProperly()
    {
        var dto = new CreateTaxDto("Special GST 6%", 6.00m, false, true);

        var result = await _gstService.CreateTaxAsync(dto);

        result.Should().NotBeNull();
        result.RatePercentage.Should().Be(6.00m);
        result.CgstPercentage.Should().Be(3.00m);
        result.SgstPercentage.Should().Be(3.00m);
        result.IgstPercentage.Should().Be(6.00m);
    }

    [Fact]
    public async Task CreateTaxAsync_WithInvalidRate_ThrowsValidationException()
    {
        var dto = new CreateTaxDto("Invalid Tax", 120.0m);

        Func<Task> act = async () => await _gstService.CreateTaxAsync(dto);

        await act.Should().ThrowAsync<FluentValidation.ValidationException>();
    }

    [Fact]
    public async Task UpdateTaxAsync_UpdatesTaxDetailsCorrectly()
    {
        var dto = new UpdateTaxDto("GST 5% Updated", 5.0m, true, true, true);

        var result = await _gstService.UpdateTaxAsync(2, dto);

        result.TaxName.Should().Be("GST 5% Updated");
        result.IsDefault.Should().BeTrue();
    }

    [Fact]
    public async Task GetHsnSacsAsync_ReturnsHsnCodes()
    {
        var list = await _gstService.GetHsnSacsAsync();

        list.Should().NotBeNull();
        list.Count.Should().Be(2);
        list.Should().Contain(h => h.Code == "2106");
    }

    [Fact]
    public async Task CreateOrUpdateHsnSacAsync_CreatesNewHsn()
    {
        var dto = new CreateHsnSacDto("1905", "Pastries and bakery goods", "HSN", 5.0m, true);

        var result = await _gstService.CreateOrUpdateHsnSacAsync(dto);

        result.Code.Should().Be("1905");
        result.DefaultGstRate.Should().Be(5.0m);
    }

    [Fact]
    public async Task GetGstConfigurationAsync_ReturnsValidConfig()
    {
        var config = await _gstService.GetGstConfigurationAsync();

        config.Should().NotBeNull();
        config.GSTIN.Should().Be("33AAAAA0000A1Z5");
        config.StateCode.Should().Be("33");
    }

    [Fact]
    public async Task UpdateGstConfigurationAsync_WithValidData_UpdatesSuccessfully()
    {
        var dto = new UpdateGstConfigurationDto(
            "33BBBBB2222B1Z6",
            "LitePOS Prime Ltd",
            "LitePOS Express",
            "Tamil Nadu",
            "33",
            false,
            true,
            "Terms applied",
            "Header",
            "Footer",
            true,
            true
        );

        var result = await _gstService.UpdateGstConfigurationAsync(dto);

        result.GSTIN.Should().Be("33BBBBB2222B1Z6");
        result.LegalName.Should().Be("LitePOS Prime Ltd");
    }

    [Fact]
    public async Task CreateCreditNoteAsync_ForIntrastate_CalculatesCgstAndSgstCorrectly()
    {
        var dto = new CreateCreditNoteDto(
            InvoiceId: 1,
            Reason: "Customer requested return for cold coffee",
            NoteType: "CreditNote",
            Items: new List<CreateCreditNoteItemDto>
            {
                new(ProductId: 1, Quantity: 1, UnitPrice: 100m, Reason: "Cold coffee")
            }
        );

        var result = await _gstService.CreateCreditNoteAsync(dto);

        result.Should().NotBeNull();
        result.CreditNoteNumber.Should().StartWith("CN-");
        result.GrandTotal.Should().Be(100m);
        result.TaxableAmount.Should().Be(95.24m);
        result.TotalTaxAmount.Should().Be(4.76m);
        result.CgstAmount.Should().Be(2.38m);
        result.SgstAmount.Should().Be(2.38m);
        result.IgstAmount.Should().Be(0m);
    }

    [Fact]
    public async Task CreateCreditNoteAsync_ForInterstateB2B_CalculatesIgstCorrectly()
    {
        var dto = new CreateCreditNoteDto(
            InvoiceId: 2,
            Reason: "Corporate order adjustment",
            NoteType: "CreditNote",
            Items: new List<CreateCreditNoteItemDto>
            {
                new(ProductId: 1, Quantity: 1, UnitPrice: 100m, Reason: "Excess billed")
            }
        );

        var result = await _gstService.CreateCreditNoteAsync(dto);

        result.Should().NotBeNull();
        result.IgstAmount.Should().Be(4.76m);
        result.CgstAmount.Should().Be(0m);
        result.SgstAmount.Should().Be(0m);
    }

    [Fact]
    public async Task GetGstSummaryAsync_AggregatesB2C_B2B_And_CreditNotesProperly()
    {
        var summary = await _gstService.GetGstSummaryAsync(
            _fixedNow.AddDays(-1),
            _fixedNow.AddDays(1)
        );

        summary.Should().NotBeNull();
        summary.B2cSummary.TotalInvoices.Should().Be(1);
        summary.B2bSummary.TotalInvoices.Should().Be(1);
        summary.B2bSummary.Invoices.Should().HaveCount(1);
        summary.B2bSummary.Invoices[0].CustomerGstin.Should().Be("29BBBBB1111B1Z2");
        summary.HsnSummary.Should().NotBeEmpty();
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

