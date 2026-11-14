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

public class CustomerServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly ICustomerService _customerService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public CustomerServiceTests()
    {
        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        _mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_CustomerTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, _mockDateTimeService.Object, _mockCurrentUserService.Object);

        SeedTestData();

        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<CustomerService>>();

        _customerService = new CustomerService(
            customerRepo,
            invoiceRepo,
            unitOfWork,
            _mockDateTimeService.Object,
            _mockCurrentUserService.Object,
            new CreateCustomerValidator(),
            new UpdateCustomerValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var cust1 = new Customer
        {
            Id = 1,
            CustomerName = "Karthik Raja",
            MobileNumber = "9876543201",
            WhatsAppNumber = "9876543201",
            Email = "karthik@example.com",
            EmailConsent = true,
            WhatsAppConsent = true,
            IsActive = true
        };

        var cust2 = new Customer
        {
            Id = 2,
            CustomerName = "Priya Sundaram",
            MobileNumber = "9876543202",
            WhatsAppNumber = "9876543202",
            Email = "priya@example.com",
            EmailConsent = true,
            WhatsAppConsent = false,
            IsActive = true
        };

        _dbContext.Customers.AddRange(cust1, cust2);

        var inv1 = new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-202611-0001",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            CashierId = 1,
            InvoiceDateUtc = _fixedNow.AddDays(-2),
            SubTotal = 300m,
            TaxableAmount = 285.71m,
            TaxAmount = 14.29m,
            GrandTotal = 300m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };
        inv1.Items.Add(new InvoiceItem
        {
            Id = 1,
            InvoiceId = 1,
            ProductId = 1,
            ProductNameSnapshot = "Cappuccino",
            Quantity = 2,
            UnitPrice = 150m,
            LineTotal = 300m
        });

        var inv2 = new Invoice
        {
            Id = 2,
            InvoiceNumber = "INV-202611-0002",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            CashierId = 1,
            InvoiceDateUtc = _fixedNow.AddDays(-1),
            SubTotal = 200m,
            TaxableAmount = 190.48m,
            TaxAmount = 9.52m,
            GrandTotal = 200m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };
        inv2.Items.Add(new InvoiceItem
        {
            Id = 2,
            InvoiceId = 2,
            ProductId = 2,
            ProductNameSnapshot = "Chocolate Waffle",
            Quantity = 1,
            UnitPrice = 200m,
            LineTotal = 200m
        });

        _dbContext.Invoices.AddRange(inv1, inv2);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetCustomersAsync_ReturnsPagedCustomersWithMetrics()
    {
        var filter = new CustomerFilterDto(PageNumber: 1, PageSize: 10);
        var result = await _customerService.GetCustomersAsync(filter);

        result.Should().NotBeNull();
        result.TotalCount.Should().Be(2);
        var karthik = result.Items.First(c => c.Id == 1);
        karthik.TotalInvoicesCount.Should().Be(2);
        karthik.TotalSpent.Should().Be(500m);
    }

    [Fact]
    public async Task GetCustomersAsync_WithSearchFilter_FiltersByNameOrMobile()
    {
        var filter = new CustomerFilterDto(Search: "Priya");
        var result = await _customerService.GetCustomersAsync(filter);

        result.TotalCount.Should().Be(1);
        result.Items.First().CustomerName.Should().Be("Priya Sundaram");
    }

    [Fact]
    public async Task GetCustomerByIdAsync_ReturnsCorrectCustomer()
    {
        var customer = await _customerService.GetCustomerByIdAsync(1);

        customer.Should().NotBeNull();
        customer.CustomerName.Should().Be("Karthik Raja");
        customer.TotalSpent.Should().Be(500m);
        customer.EmailConsent.Should().BeTrue();
    }

    [Fact]
    public async Task GetCustomerByIdAsync_WithInvalidId_ThrowsKeyNotFoundException()
    {
        Func<Task> act = async () => await _customerService.GetCustomerByIdAsync(999);
        await act.Should().ThrowAsync<KeyNotFoundException>();
    }

    [Fact]
    public async Task LookupCustomersAsync_ReturnsMatchingCustomers()
    {
        var results = await _customerService.LookupCustomersAsync("9876543201");

        results.Should().NotBeEmpty();
        results.First().CustomerName.Should().Be("Karthik Raja");
    }

    [Fact]
    public async Task CreateCustomerAsync_WithValidData_CreatesSuccessfully()
    {
        var dto = new CreateCustomerDto(
            CustomerName: "Anand Kumar",
            MobileNumber: "9876543203",
            Email: "anand@example.com",
            EmailConsent: true,
            WhatsAppConsent: true
        );

        var result = await _customerService.CreateCustomerAsync(dto);

        result.Should().NotBeNull();
        result.CustomerName.Should().Be("Anand Kumar");
        result.MobileNumber.Should().Be("9876543203");
        result.WhatsAppConsent.Should().BeTrue();
    }

    [Fact]
    public async Task CreateCustomerAsync_WithDuplicateMobile_ThrowsInvalidOperationException()
    {
        var dto = new CreateCustomerDto(
            CustomerName: "Duplicate Test",
            MobileNumber: "9876543201" // Already exists
        );

        Func<Task> act = async () => await _customerService.CreateCustomerAsync(dto);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*already exists*");
    }

    [Fact]
    public async Task CreateCustomerAsync_WithInvalidMobile_ThrowsValidationException()
    {
        var dto = new CreateCustomerDto(
            CustomerName: "Invalid Mobile",
            MobileNumber: "12345" // Invalid
        );

        Func<Task> act = async () => await _customerService.CreateCustomerAsync(dto);
        await act.Should().ThrowAsync<FluentValidation.ValidationException>();
    }

    [Fact]
    public async Task UpdateCustomerAsync_UpdatesCustomerDetailsProperly()
    {
        var dto = new UpdateCustomerDto(
            CustomerName: "Karthik R. Updated",
            MobileNumber: "9876543201",
            Email: "karthik.new@example.com",
            EmailConsent: true,
            WhatsAppConsent: true,
            IsActive: true
        );

        var result = await _customerService.UpdateCustomerAsync(1, dto);

        result.CustomerName.Should().Be("Karthik R. Updated");
        result.Email.Should().Be("karthik.new@example.com");
    }

    [Fact]
    public async Task GetCustomerPurchaseHistoryAsync_CalculatesTotalSpentAndReturnsInvoices()
    {
        var history = await _customerService.GetCustomerPurchaseHistoryAsync(1);

        history.Should().NotBeNull();
        history.CustomerId.Should().Be(1);
        history.TotalInvoices.Should().Be(2);
        history.TotalSpent.Should().Be(500m);
        history.Invoices.Should().HaveCount(2);
        history.Invoices.First().InvoiceNumber.Should().Be("INV-202611-0002");
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

