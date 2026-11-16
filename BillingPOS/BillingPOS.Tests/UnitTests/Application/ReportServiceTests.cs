using System.Text;
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
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class ReportServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IReportService _reportService;
    private readonly DateTime _baseDate = new(2026, 11, 13, 12, 0, 0, DateTimeKind.Utc);

    public ReportServiceTests()
    {
        var mockCurrentUserService = new Mock<ICurrentUserService>();
        mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        mockCurrentUserService.Setup(s => s.Username).Returns("admin");

        var mockDateTimeService = new Mock<IDateTimeService>();
        mockDateTimeService.Setup(s => s.UtcNow).Returns(_baseDate);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_ReportTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, mockDateTimeService.Object, mockCurrentUserService.Object);

        SeedTestData();

        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var invoiceItemRepo = new GenericRepository<InvoiceItem>(_dbContext);
        var paymentRepo = new GenericRepository<Payment>(_dbContext);
        var refundRepo = new GenericRepository<Refund>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var categoryRepo = new GenericRepository<Category>(_dbContext);

        _reportService = new ReportService(
            invoiceRepo,
            invoiceItemRepo,
            paymentRepo,
            refundRepo,
            productRepo,
            categoryRepo);
    }

    private void SeedTestData()
    {
        var company = new Company { Id = 1, CompanyName = "LitePOS Test Corp", BusinessType = BusinessType.Cafe };
        var shop = new Shop { Id = 1, CompanyId = 1, ShopName = "Test Branch" };
        var cashier = new User { Id = 1, CompanyId = 1, ShopId = 1, Username = "cashier1", FullName = "Arun Cashier" };
        var customer = new Customer { Id = 1, CustomerName = "Karthik Raja", MobileNumber = "9876543201" };

        var catBeverages = new Category { Id = 1, CategoryName = "Beverages" };
        var catDesserts = new Category { Id = 2, CategoryName = "Desserts" };

        var prodCoffee = new Product
        {
            Id = 1,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Espresso Coffee",
            SellingPrice = 100.0m,
            TaxPercentage = 5.0m,
            HSNCode = "996331",
            Category = catBeverages
        };
        var prodSundae = new Product
        {
            Id = 2,
            CompanyId = 1,
            CategoryId = 2,
            ProductName = "Chocolate Sundae",
            SellingPrice = 200.0m,
            TaxPercentage = 18.0m,
            HSNCode = "21050000",
            Category = catDesserts
        };

        _dbContext.Companies.Add(company);
        _dbContext.Shops.Add(shop);
        _dbContext.Users.Add(cashier);
        _dbContext.Customers.Add(customer);
        _dbContext.Categories.AddRange(catBeverages, catDesserts);
        _dbContext.Products.AddRange(prodCoffee, prodSundae);

        // Active Invoice 1 (Today at 10:00 UTC)
        var inv1 = new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-20261113-0001",
            CompanyId = 1,
            ShopId = 1,
            CashierId = 1,
            Cashier = cashier,
            CustomerId = 1,
            Customer = customer,
            InvoiceDateUtc = new DateTime(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc),
            SubTotal = 300.0m,
            DiscountAmount = 20.0m,
            TaxableAmount = 280.0m,
            TaxAmount = 24.0m,
            GrandTotal = 304.0m,
            PaidAmount = 304.0m,
            BalanceAmount = 0.0m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };

        var item1 = new InvoiceItem
        {
            Id = 1,
            InvoiceId = 1,
            ProductId = 1,
            ProductNameSnapshot = "Espresso Coffee",
            UnitPrice = 100.0m,
            Quantity = 2,
            DiscountAmount = 10.0m,
            TaxPercentage = 5.0m,
            TaxAmount = 9.5m,
            LineTotal = 199.5m
        };

        var item2 = new InvoiceItem
        {
            Id = 2,
            InvoiceId = 1,
            ProductId = 2,
            ProductNameSnapshot = "Chocolate Sundae",
            UnitPrice = 200.0m,
            Quantity = 1,
            DiscountAmount = 10.0m,
            TaxPercentage = 18.0m,
            TaxAmount = 14.5m,
            LineTotal = 104.5m
        };

        var pay1 = new Payment
        {
            Id = 1,
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 304.0m,
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = new DateTime(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc)
        };

        // Active Invoice 2 (Today at 14:00 UTC)
        var inv2 = new Invoice
        {
            Id = 2,
            InvoiceNumber = "INV-20261113-0002",
            CompanyId = 1,
            ShopId = 1,
            CashierId = 1,
            Cashier = cashier,
            CustomerId = 1,
            Customer = customer,
            InvoiceDateUtc = new DateTime(2026, 11, 13, 14, 0, 0, DateTimeKind.Utc),
            SubTotal = 200.0m,
            DiscountAmount = 0.0m,
            TaxableAmount = 200.0m,
            TaxAmount = 36.0m,
            GrandTotal = 236.0m,
            PaidAmount = 236.0m,
            BalanceAmount = 0.0m,
            PaymentStatus = PaymentStatus.Paid,
            InvoiceStatus = InvoiceStatus.Active
        };

        var item3 = new InvoiceItem
        {
            Id = 3,
            InvoiceId = 2,
            ProductId = 2,
            ProductNameSnapshot = "Chocolate Sundae",
            UnitPrice = 200.0m,
            Quantity = 1,
            DiscountAmount = 0.0m,
            TaxPercentage = 18.0m,
            TaxAmount = 36.0m,
            LineTotal = 236.0m
        };

        var pay2 = new Payment
        {
            Id = 2,
            InvoiceId = 2,
            PaymentMode = PaymentMode.UPI,
            Amount = 236.0m,
            PaymentStatus = PaymentStatus.Paid,
            CreatedAtUtc = new DateTime(2026, 11, 13, 14, 0, 0, DateTimeKind.Utc)
        };

        // Cancelled Invoice 3 (Should be excluded from revenue)
        var inv3 = new Invoice
        {
            Id = 3,
            InvoiceNumber = "INV-20261113-0003",
            CompanyId = 1,
            ShopId = 1,
            CashierId = 1,
            Cashier = cashier,
            InvoiceDateUtc = new DateTime(2026, 11, 13, 15, 0, 0, DateTimeKind.Utc),
            SubTotal = 500.0m,
            GrandTotal = 500.0m,
            InvoiceStatus = InvoiceStatus.Cancelled
        };

        // Refund of 50.0m
        var refund1 = new Refund
        {
            Id = 1,
            InvoiceId = 1,
            Amount = 50.0m,
            PaymentMode = PaymentMode.Cash,
            Reason = "Customer changed mind",
            ProcessedBy = "cashier1",
            CreatedAtUtc = new DateTime(2026, 11, 13, 11, 0, 0, DateTimeKind.Utc)
        };

        _dbContext.Invoices.AddRange(inv1, inv2, inv3);
        _dbContext.InvoiceItems.AddRange(item1, item2, item3);
        _dbContext.Payments.AddRange(pay1, pay2);
        _dbContext.Refunds.Add(refund1);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetSalesSummaryAsync_CalculatesMetricsCorrectly()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetSalesSummaryAsync(filter);

        result.TotalInvoices.Should().Be(3);
        result.TotalActiveInvoices.Should().Be(2);
        result.TotalCancelledInvoices.Should().Be(1);
        result.GrossSales.Should().Be(500.0m);
        result.TotalDiscount.Should().Be(20.0m);
        result.NetSales.Should().Be(480.0m);
        result.TotalTax.Should().Be(60.0m);
        result.GrandTotalSales.Should().Be(540.0m);
        result.TotalRefunds.Should().Be(50.0m);
        result.NetRevenue.Should().Be(490.0m);
        result.TotalCashCollected.Should().Be(304.0m);
        result.TotalUpiCollected.Should().Be(236.0m);
        result.AverageOrderValue.Should().Be(270.0m);
    }

    [Fact]
    public async Task GetDailySalesReportAsync_GroupsByDateAccurately()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetDailySalesReportAsync(filter);

        result.Should().HaveCount(1);
        result[0].Date.Should().Be(new DateTime(2026, 11, 13));
        result[0].InvoiceCount.Should().Be(2);
        result[0].GrossSales.Should().Be(500.0m);
        result[0].NetSales.Should().Be(540.0m);
        result[0].CashAmount.Should().Be(304.0m);
        result[0].UpiAmount.Should().Be(236.0m);
    }

    [Fact]
    public async Task GetProductSalesReportAsync_RanksTopSellersCorrectly()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetProductSalesReportAsync(filter);

        result.Should().HaveCount(2);
        result[0].ProductName.Should().Be("Chocolate Sundae");
        result[0].QuantitySold.Should().Be(2);
        result[1].ProductName.Should().Be("Espresso Coffee");
        result[1].QuantitySold.Should().Be(2);
    }

    [Fact]
    public async Task GetCategorySalesReportAsync_AggregatesCategories()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetCategorySalesReportAsync(filter);

        result.Should().HaveCount(2);
        result.Select(c => c.CategoryName).Should().Contain("Beverages");
        result.Select(c => c.CategoryName).Should().Contain("Desserts");
    }

    [Fact]
    public async Task GetCashierPerformanceReportAsync_AttributesSalesProperly()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetCashierPerformanceReportAsync(filter);

        result.Should().HaveCount(1);
        result[0].CashierName.Should().Be("Arun Cashier");
        result[0].InvoicesCount.Should().Be(2);
        result[0].TotalSales.Should().Be(540.0m);
        result[0].CashCollected.Should().Be(304.0m);
        result[0].DigitalCollected.Should().Be(236.0m);
        result[0].RefundsHandled.Should().Be(50.0m);
    }

    [Fact]
    public async Task GetGstSummaryReportAsync_CalculatesTaxSlabsAndHsnCorrectly()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetGstSummaryReportAsync(filter);

        result.Slabs.Should().HaveCount(2);
        result.TotalGst.Should().Be(60.0m);
        result.TotalCgst.Should().Be(30.0m);
        result.TotalSgst.Should().Be(30.0m);

        result.HsnSummary.Should().HaveCount(2);
    }

    [Fact]
    public async Task GetHourlySalesReportAsync_GroupsByHourSlots()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetHourlySalesReportAsync(filter);

        result.Should().HaveCount(24);
        var hour10 = result.First(h => h.Hour == 10);
        hour10.OrderCount.Should().Be(1);
        hour10.TotalSales.Should().Be(304.0m);

        var hour14 = result.First(h => h.Hour == 14);
        hour14.OrderCount.Should().Be(1);
        hour14.TotalSales.Should().Be(236.0m);
    }

    [Fact]
    public async Task GetPaymentModeBreakdownAsync_CalculatesPaymentShares()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetPaymentModeBreakdownAsync(filter);

        result.Should().HaveCount(2);
        result.First(p => p.PaymentMode == "Cash").TotalAmount.Should().Be(304.0m);
        result.First(p => p.PaymentMode == "UPI").TotalAmount.Should().Be(236.0m);
    }

    [Fact]
    public async Task ExportSalesReportCsvAsync_GeneratesValidCsvBytes()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var bytes = await _reportService.ExportSalesReportCsvAsync(filter);

        bytes.Should().NotBeNullOrEmpty();
        var csv = Encoding.UTF8.GetString(bytes);
        csv.Should().Contain("Invoice Number,Date (UTC),Status,Cashier,Customer,SubTotal,Discount,Taxable,Tax,Grand Total,Paid,Balance");
        csv.Should().Contain("INV-20261113-0001");
        csv.Should().Contain("Arun Cashier");
        csv.Should().Contain("Karthik Raja");
    }

    [Fact]
    public async Task GetSalesSummaryAsync_ExcludesCancelledInvoicesFromRevenue()
    {
        var filter = new ReportDateRangeFilterDto(
            FromDateUtc: new DateTime(2026, 11, 13, 0, 0, 0, DateTimeKind.Utc),
            ToDateUtc: new DateTime(2026, 11, 13, 23, 59, 59, DateTimeKind.Utc));

        var result = await _reportService.GetSalesSummaryAsync(filter);

        result.GrossSales.Should().Be(500.0m);
        result.TotalCancelledInvoices.Should().Be(1);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}
