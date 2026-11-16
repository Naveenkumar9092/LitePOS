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

public class BillingServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IBillingService _billingService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public BillingServiceTests()
    {
        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_BillingTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options);

        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        _mockCurrentUserService.Setup(s => s.ShopId).Returns(1);
        _mockCurrentUserService.Setup(s => s.CompanyId).Returns(1);

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        SeedTestData();

        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var invoiceItemRepo = new GenericRepository<InvoiceItem>(_dbContext);
        var paymentRepo = new GenericRepository<Payment>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var shopRepo = new GenericRepository<Shop>(_dbContext);
        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var userRepo = new GenericRepository<User>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<BillingService>>();

        _billingService = new BillingService(
            invoiceRepo,
            invoiceItemRepo,
            paymentRepo,
            productRepo,
            companyRepo,
            shopRepo,
            customerRepo,
            userRepo,
            unitOfWork,
            _mockCurrentUserService.Object,
            _mockDateTimeService.Object,
            new CreateInvoiceValidator(),
            new HoldBillValidator(),
            new CancelBillValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "LitePOS Cafe",
            BusinessType = BusinessType.Cafe,
            IsActive = true
        };
        _dbContext.Companies.Add(company);

        var shop = new Shop
        {
            Id = 1,
            CompanyId = 1,
            ShopName = "Main Branch",
            IsActive = true
        };
        _dbContext.Shops.Add(shop);

        var user = new User
        {
            Id = 1,
            CompanyId = 1,
            ShopId = 1,
            FullName = "Cashier One",
            Username = "cashier1",
            RoleId = 3,
            IsActive = true
        };
        _dbContext.Users.Add(user);

        var customer = new Customer
        {
            Id = 1,
            CustomerName = "John Doe",
            MobileNumber = "9876543210",
            IsActive = true
        };
        _dbContext.Customers.Add(customer);

        var category = new Category
        {
            Id = 1,
            CategoryName = "Coffee",
            DisplayOrder = 1,
            IsActive = true
        };
        _dbContext.Categories.Add(category);

        var products = new List<Product>
        {
            new Product
            {
                Id = 1,
                ProductGuid = Guid.NewGuid(),
                CompanyId = 1,
                CategoryId = 1,
                ProductName = "Espresso",
                SellingPrice = 100m,
                TaxPercentage = 5m,
                IsAvailable = true,
                IsActive = true
            },
            new Product
            {
                Id = 2,
                ProductGuid = Guid.NewGuid(),
                CompanyId = 1,
                CategoryId = 1,
                ProductName = "Seasonal Latte",
                SellingPrice = 150m,
                TaxPercentage = 5m,
                IsAvailable = false, // Out of stock
                IsActive = true
            }
        };
        _dbContext.Products.AddRange(products);

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateInvoiceAsync_ValidCart_CalculatesTotals_CreatesInvoiceAndPayment()
    {
        // 2 Espressos @ 100 each = 200 SubTotal
        // Line tax: 200 * 5% = 10.00
        // Grand Total = 210.00
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 1, ProductNameSnapshot: "Espresso", Quantity: 2, UnitPrice: 100m, DiscountAmount: 0m, TaxPercentage: 5m)
        };

        var dto = new CreateInvoiceDto(
            CustomerId: 1,
            DeviceId: "POS-01",
            Items: items,
            DiscountAmount: 0m,
            PaidAmount: 210m,
            PaymentMode: PaymentMode.Cash
        );

        var result = await _billingService.CreateInvoiceAsync(dto);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.InvoiceNumber.Should().StartWith("INV-20261113-");
        result.Data.SubTotal.Should().Be(200m);
        result.Data.TaxAmount.Should().Be(10m);
        result.Data.GrandTotal.Should().Be(210m);
        result.Data.PaidAmount.Should().Be(210m);
        result.Data.BalanceAmount.Should().Be(0m);
        result.Data.PaymentStatus.Should().Be(PaymentStatus.Paid);
        result.Data.InvoiceStatus.Should().Be(InvoiceStatus.Active);
        result.Data.Items.Should().HaveCount(1);
        result.Data.Payments.Should().HaveCount(1);
        result.Data.Payments[0].PaymentMode.Should().Be(PaymentMode.Cash);
        result.Data.Payments[0].Amount.Should().Be(210m);
    }

    [Fact]
    public async Task CreateInvoiceAsync_UnavailableProduct_ReturnsError()
    {
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 2, ProductNameSnapshot: "Seasonal Latte", Quantity: 1, UnitPrice: 150m)
        };

        var dto = new CreateInvoiceDto(
            CustomerId: null,
            DeviceId: "POS-01",
            Items: items,
            PaidAmount: 150m
        );

        var result = await _billingService.CreateInvoiceAsync(dto);

        result.Success.Should().BeFalse();
        result.Message.Should().Contain("currently unavailable");
    }

    [Fact]
    public async Task CreateInvoiceAsync_EmptyCart_FailsValidation()
    {
        var dto = new CreateInvoiceDto(
            CustomerId: null,
            DeviceId: "POS-01",
            Items: new List<CreateInvoiceItemDto>()
        );

        var result = await _billingService.CreateInvoiceAsync(dto);

        result.Success.Should().BeFalse();
        result.Errors.Should().NotBeEmpty();
    }

    [Fact]
    public async Task HoldBillAsync_ValidItems_CreatesHeldInvoice()
    {
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 1, ProductNameSnapshot: "Espresso", Quantity: 1, UnitPrice: 100m, TaxPercentage: 5m)
        };

        var dto = new HoldBillDto(
            CustomerId: 1,
            DeviceId: "POS-01",
            Note: "Customer stepped out for cash",
            Items: items
        );

        var result = await _billingService.HoldBillAsync(dto);

        result.Success.Should().BeTrue();
        result.Data!.InvoiceStatus.Should().Be(InvoiceStatus.Held);
        result.Data.InvoiceNumber.Should().StartWith("HOLD-20261113-");
        result.Data.PaymentStatus.Should().Be(PaymentStatus.Pending);

        var heldList = await _billingService.GetHeldBillsAsync();
        heldList.Success.Should().BeTrue();
        heldList.Data.Should().HaveCount(1);
    }

    [Fact]
    public async Task ResumeBillAsync_HeldBill_ReturnsHeldBill()
    {
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 1, ProductNameSnapshot: "Espresso", Quantity: 1, UnitPrice: 100m)
        };

        var holdDto = new HoldBillDto(1, "POS-01", "Hold", items);
        var holdResult = await _billingService.HoldBillAsync(holdDto);

        var resumeResult = await _billingService.ResumeBillAsync(holdResult.Data!.InvoiceId);

        resumeResult.Success.Should().BeTrue();
        resumeResult.Data!.InvoiceId.Should().Be(holdResult.Data.InvoiceId);
        resumeResult.Data.InvoiceStatus.Should().Be(InvoiceStatus.Held);
    }

    [Fact]
    public async Task CancelBillAsync_ActiveInvoice_CancelsSuccessfully()
    {
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 1, ProductNameSnapshot: "Espresso", Quantity: 1, UnitPrice: 100m, TaxPercentage: 5m)
        };

        var createDto = new CreateInvoiceDto(1, "POS-01", items, 0m, 105m, PaymentMode.Cash);
        var created = await _billingService.CreateInvoiceAsync(createDto);

        var cancelResult = await _billingService.CancelBillAsync(created.Data!.InvoiceId, "Customer ordered wrong item");

        cancelResult.Success.Should().BeTrue();

        var invoice = await _dbContext.Invoices.FindAsync(created.Data.InvoiceId);
        invoice!.InvoiceStatus.Should().Be(InvoiceStatus.Cancelled);
    }

    [Fact]
    public async Task ReprintBillAsync_ExistingInvoice_ReturnsInvoiceDetails()
    {
        var items = new List<CreateInvoiceItemDto>
        {
            new(ProductId: 1, ProductNameSnapshot: "Espresso", Quantity: 1, UnitPrice: 100m, TaxPercentage: 5m)
        };

        var createDto = new CreateInvoiceDto(1, "POS-01", items, 0m, 105m, PaymentMode.Cash);
        var created = await _billingService.CreateInvoiceAsync(createDto);

        var reprintResult = await _billingService.ReprintBillAsync(created.Data!.InvoiceId);

        reprintResult.Success.Should().BeTrue();
        reprintResult.Data!.InvoiceNumber.Should().Be(created.Data.InvoiceNumber);
        reprintResult.Data.Items.Should().HaveCount(1);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}
