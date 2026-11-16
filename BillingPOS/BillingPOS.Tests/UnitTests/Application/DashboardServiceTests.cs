using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using BillingPOS.Infrastructure.Repositories;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class DashboardServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IDashboardService _dashboardService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public DashboardServiceTests()
    {
        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_DashboardTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options);

        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(3);
        _mockCurrentUserService.Setup(s => s.Username).Returns("cashier1");
        _mockCurrentUserService.Setup(s => s.Role).Returns("Cashier");

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        SeedTestData();

        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var paymentRepo = new GenericRepository<Payment>(_dbContext);
        var orderRepo = new GenericRepository<Order>(_dbContext);
        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var userRepo = new GenericRepository<User>(_dbContext);
        var deviceRepo = new GenericRepository<Device, string>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var shopRepo = new GenericRepository<Shop>(_dbContext);
        var auditLogRepo = new GenericRepository<LoginAuditLog>(_dbContext);

        _dashboardService = new DashboardService(
            invoiceRepo,
            paymentRepo,
            orderRepo,
            customerRepo,
            userRepo,
            deviceRepo,
            companyRepo,
            shopRepo,
            auditLogRepo,
            _mockCurrentUserService.Object,
            _mockDateTimeService.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "LitePOS Gourmet Cafe",
            LegalName = "LitePOS Foods Pvt Ltd",
            BusinessType = BusinessType.Cafe,
            GSTIN = "33AAAAA0000A1Z5",
            Email = "contact@liteposcafe.com",
            MobileNumber = "+91 9876543210",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Companies.Add(company);

        var shop = new Shop
        {
            Id = 1,
            CompanyId = 1,
            ShopName = "Chennai Main Branch",
            AddressLine1 = "100 Feet Road",
            City = "Chennai",
            State = "Tamil Nadu",
            Pincode = "600042",
            Country = "India",
            ContactNumber = "+91 9876543210",
            Email = "branch@liteposcafe.com",
            CurrencyCode = "INR",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Shops.Add(shop);

        var userAdmin = new User
        {
            Id = 2,
            CompanyId = 1,
            ShopId = 1,
            RoleId = 2,
            Username = "admin",
            FullName = "Priya Sundaram",
            Email = "admin@liteposcafe.com",
            PasswordHash = "hash",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };

        var userCashier = new User
        {
            Id = 3,
            CompanyId = 1,
            ShopId = 1,
            RoleId = 3,
            Username = "cashier1",
            FullName = "Anand Kumar",
            Email = "cashier1@liteposcafe.com",
            PasswordHash = "hash",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Users.AddRange(userAdmin, userCashier);

        var customer = new Customer
        {
            Id = 1,
            CustomerGuid = Guid.NewGuid(),
            CustomerName = "Karthik Raja",
            MobileNumber = "9876501234",
            Email = "karthik@example.com",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Customers.Add(customer);

        var device = new Device
        {
            Id = "POS-MAIN-01",
            DeviceName = "Main Counter POS",
            AppVersion = "1.0.0",
            IsOnline = true,
            LastSyncTimeUtc = _fixedNow,
            RegisteredAtUtc = _fixedNow
        };
        _dbContext.Devices.Add(device);

        var inv1 = new Invoice
        {
            Id = 1,
            InvoiceGuid = Guid.NewGuid(),
            InvoiceNumber = "INV-20261113-0001",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            CashierId = 3,
            DeviceId = "POS-MAIN-01",
            InvoiceDateUtc = _fixedNow.AddHours(-1),
            SubTotal = 300m,
            TaxAmount = 15m,
            DiscountAmount = 0m,
            GrandTotal = 315m,
            PaidAmount = 315m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active,
            CreatedAtUtc = _fixedNow.AddHours(-1)
        };

        var inv2 = new Invoice
        {
            Id = 2,
            InvoiceGuid = Guid.NewGuid(),
            InvoiceNumber = "INV-20261113-0002",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            CashierId = 3,
            DeviceId = "POS-MAIN-01",
            InvoiceDateUtc = _fixedNow.AddMinutes(-30),
            SubTotal = 400m,
            TaxAmount = 20m,
            DiscountAmount = 20m,
            GrandTotal = 400m,
            PaidAmount = 400m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active,
            CreatedAtUtc = _fixedNow.AddMinutes(-30)
        };
        _dbContext.Invoices.AddRange(inv1, inv2);

        var pay1 = new Payment
        {
            Id = 1,
            PaymentGuid = Guid.NewGuid(),
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 315m,
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = _fixedNow.AddHours(-1)
        };

        var pay2 = new Payment
        {
            Id = 2,
            PaymentGuid = Guid.NewGuid(),
            InvoiceId = 2,
            PaymentMode = PaymentMode.UPI,
            Amount = 400m,
            TransactionReference = "UPI123456789",
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = _fixedNow.AddMinutes(-30)
        };
        _dbContext.Payments.AddRange(pay1, pay2);

        var order1 = new Order
        {
            Id = 1,
            OrderGuid = Guid.NewGuid(),
            OrderNumber = "ORD-20261113-0001",
            CustomerId = 1,
            OrderType = OrderType.CounterSale,
            OrderStatus = OrderStatus.Completed,
            SubTotal = 300m,
            GrandTotal = 315m,
            CreatedBy = "cashier1",
            CreatedAtUtc = _fixedNow.AddHours(-1)
        };
        _dbContext.Orders.Add(order1);

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetSAdminDashboardAsync_ShouldReturnValidShopAndSystemHealth()
    {
        var result = await _dashboardService.GetSAdminDashboardAsync();

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.ShopInfo.CompanyName.Should().Be("LitePOS Gourmet Cafe");
        result.Data.ShopInfo.ShopName.Should().Be("Chennai Main Branch");
        result.Data.TotalUsers.Should().Be(2);
        result.Data.ActiveUsers.Should().Be(2);
        result.Data.TotalInvoices.Should().Be(2);
        result.Data.TotalSales.Should().Be(715m);
        result.Data.AppHealth.Status.Should().Be("Healthy");
    }

    [Fact]
    public async Task GetAdminDashboardAsync_ShouldReturnAccurateSalesAndPaymentBreakdown()
    {
        var result = await _dashboardService.GetAdminDashboardAsync(_fixedNow);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.TodaySales.Should().Be(715m);
        result.Data.TodayInvoices.Should().Be(2);
        result.Data.CashSales.Should().Be(315m);
        result.Data.UpiSales.Should().Be(400m);
        result.Data.CardSales.Should().Be(0m);

        result.Data.TotalCustomers.Should().Be(1);
        result.Data.CompletedOrders.Should().Be(1);
        result.Data.CashierWiseSales.Should().ContainSingle();
        result.Data.CashierWiseSales.First().CashierName.Should().Be("Anand Kumar");
        result.Data.CashierWiseSales.First().TotalSales.Should().Be(715m);
    }

    [Fact]
    public async Task GetCashierDashboardAsync_ShouldCalculateDrawerBalanceAndCollections()
    {
        var result = await _dashboardService.GetCashierDashboardAsync(cashierId: 3, date: _fixedNow);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.CashierId.Should().Be(3);
        result.Data.CashierName.Should().Be("Anand Kumar");
        result.Data.TodaySales.Should().Be(715m);
        result.Data.TodayInvoices.Should().Be(2);
        result.Data.CashCollected.Should().Be(315m);
        result.Data.UpiCollected.Should().Be(400m);

        // Shift summary drawer check: opening float 1000 + 315 cash = 1315 cash on hand
        result.Data.ShiftSummary.OpeningFloat.Should().Be(1000m);
        result.Data.ShiftSummary.TotalCollected.Should().Be(715m);
        result.Data.ShiftSummary.CashOnHand.Should().Be(1315m);
    }

    [Fact]
    public async Task GetSalesSummaryAsync_ShouldReturnAggregatedMetrics()
    {
        var result = await _dashboardService.GetSalesSummaryAsync("today");

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.TotalSales.Should().Be(715m);
        result.Data.TotalInvoices.Should().Be(2);
        result.Data.AverageBillValue.Should().Be(357.5m);
        result.Data.TotalTax.Should().Be(35m);
    }

    [Fact]
    public async Task GetPaymentSummaryAsync_ShouldGroupPaymentsByMode()
    {
        var result = await _dashboardService.GetPaymentSummaryAsync("today");

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.CashAmount.Should().Be(315m);
        result.Data.UpiAmount.Should().Be(400m);
        result.Data.CardAmount.Should().Be(0m);
        result.Data.TotalAmount.Should().Be(715m);
    }

    [Fact]
    public async Task GetRecentTransactionsAsync_ShouldReturnInvoicesDesc()
    {
        var result = await _dashboardService.GetRecentTransactionsAsync(limit: 5);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Count.Should().Be(2);
        result.Data.First().InvoiceNumber.Should().Be("INV-20261113-0002");
        result.Data.First().CustomerName.Should().Be("Karthik Raja");
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}
