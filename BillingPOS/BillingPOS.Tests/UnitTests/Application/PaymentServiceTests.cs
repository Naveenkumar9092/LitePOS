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

public class PaymentServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IPaymentService _paymentService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public PaymentServiceTests()
    {
        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        _mockCurrentUserService.Setup(s => s.Username).Returns("cashier1");

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_PaymentTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, _mockDateTimeService.Object, _mockCurrentUserService.Object);

        SeedTestData();

        var paymentRepo = new GenericRepository<Payment>(_dbContext);
        var refundRepo = new GenericRepository<Refund>(_dbContext);
        var cashRegisterRepo = new GenericRepository<CashRegister>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var orderRepo = new GenericRepository<Order>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<PaymentService>>();

        _paymentService = new PaymentService(
            paymentRepo,
            refundRepo,
            cashRegisterRepo,
            invoiceRepo,
            orderRepo,
            unitOfWork,
            _mockCurrentUserService.Object,
            _mockDateTimeService.Object,
            new ProcessPaymentValidator(),
            new ProcessSplitPaymentValidator(),
            new ProcessRefundValidator(),
            new OpenCashRegisterValidator(),
            new CloseCashRegisterValidator(),
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

        var customer = new Customer
        {
            Id = 1,
            CustomerName = "Sneha Reddy",
            MobileNumber = "9876543210",
            IsActive = true
        };
        _dbContext.Customers.Add(customer);

        var invoice = new Invoice
        {
            Id = 1,
            InvoiceNumber = "INV-20261113-0001",
            CompanyId = 1,
            ShopId = 1,
            CustomerId = 1,
            CashierId = 1,
            DeviceId = "POS-TERMINAL-01",
            GrandTotal = 500.00m,
            PaidAmount = 0.00m,
            BalanceAmount = 500.00m,
            PaymentStatus = PaymentStatus.Pending,
            InvoiceStatus = InvoiceStatus.Active,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Invoices.Add(invoice);

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task ProcessPaymentAsync_CashPayment_UpdatesInvoicePaidAndBalance()
    {
        // Arrange
        var dto = new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 500.00m
        };

        // Act
        var result = await _paymentService.ProcessPaymentAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Amount.Should().Be(500.00m);
        result.Data.PaymentMode.Should().Be(PaymentMode.Cash);
        result.Data.PaymentStatus.Should().Be(PaymentStatus.Paid);

        var invoice = await _dbContext.Invoices.FindAsync(1L);
        invoice!.PaidAmount.Should().Be(500.00m);
        invoice.BalanceAmount.Should().Be(0.00m);
        invoice.PaymentStatus.Should().Be(PaymentStatus.Paid);
    }

    [Fact]
    public async Task ProcessPaymentAsync_UPIPaymentWithoutReference_FailsValidation()
    {
        // Arrange: UPI without reference violates rule: "Do not mark an unverified UPI payment as paid"
        var dto = new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.UPI,
            Amount = 300.00m,
            TransactionReference = null
        };

        // Act
        var result = await _paymentService.ProcessPaymentAsync(dto);

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("Validation failed");
    }

    [Fact]
    public async Task ProcessPaymentAsync_UPIPaymentWithReference_Succeeds()
    {
        // Arrange
        var dto = new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.UPI,
            Amount = 250.00m,
            TransactionReference = "UPI-REF-998877"
        };

        // Act
        var result = await _paymentService.ProcessPaymentAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.TransactionReference.Should().Be("UPI-REF-998877");

        var invoice = await _dbContext.Invoices.FindAsync(1L);
        invoice!.PaidAmount.Should().Be(250.00m);
        invoice.BalanceAmount.Should().Be(250.00m);
        invoice.PaymentStatus.Should().Be(PaymentStatus.PartiallyPaid);
    }

    [Fact]
    public async Task ProcessSplitPaymentAsync_CashAndUPI_UpdatesTotalsAndSetsStatusToPaid()
    {
        // Arrange: Total 500 = Cash 200 + UPI 300
        var dto = new ProcessSplitPaymentDto
        {
            InvoiceId = 1,
            Payments = new List<SplitPaymentItemDto>
            {
                new() { PaymentMode = PaymentMode.Cash, Amount = 200.00m },
                new() { PaymentMode = PaymentMode.UPI, Amount = 300.00m, TransactionReference = "UPI-SPLIT-1234" }
            }
        };

        // Act
        var result = await _paymentService.ProcessSplitPaymentAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data.Should().HaveCount(2);

        var invoice = await _dbContext.Invoices.FindAsync(1L);
        invoice!.PaidAmount.Should().Be(500.00m);
        invoice.BalanceAmount.Should().Be(0.00m);
        invoice.PaymentStatus.Should().Be(PaymentStatus.Paid);
    }

    [Fact]
    public async Task ProcessSplitPaymentAsync_ExceedsBalance_Fails()
    {
        // Arrange: Split total 600 exceeds invoice grand total 500
        var dto = new ProcessSplitPaymentDto
        {
            InvoiceId = 1,
            Payments = new List<SplitPaymentItemDto>
            {
                new() { PaymentMode = PaymentMode.Cash, Amount = 300.00m },
                new() { PaymentMode = PaymentMode.Card, Amount = 300.00m, TransactionReference = "CARD-AUTH-111" }
            }
        };

        // Act
        var result = await _paymentService.ProcessSplitPaymentAsync(dto);

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("exceeds remaining balance");
    }

    [Fact]
    public async Task ProcessRefundAsync_ValidAmount_RecordsNegativePaymentAndUpdatesInvoice()
    {
        // Arrange: First pay invoice
        await _paymentService.ProcessPaymentAsync(new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 500.00m
        });

        // Act: Issue partial refund of 200
        var refundDto = new ProcessRefundDto
        {
            InvoiceId = 1,
            Amount = 200.00m,
            Reason = "Customer returned one item",
            AuthorizedBy = "Admin"
        };
        var result = await _paymentService.ProcessRefundAsync(refundDto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.Amount.Should().Be(-200.00m);
        result.Data.PaymentStatus.Should().Be(PaymentStatus.Refunded);

        var invoice = await _dbContext.Invoices.FindAsync(1L);
        invoice!.PaidAmount.Should().Be(300.00m);
        invoice.BalanceAmount.Should().Be(200.00m);
        invoice.PaymentStatus.Should().Be(PaymentStatus.PartiallyPaid);
    }

    [Fact]
    public async Task ProcessRefundAsync_ExceedsPaidAmount_Fails()
    {
        // Arrange: Pay only 200
        await _paymentService.ProcessPaymentAsync(new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 200.00m
        });

        // Act: Try to refund 300
        var refundDto = new ProcessRefundDto
        {
            InvoiceId = 1,
            Amount = 300.00m,
            Reason = "Refund"
        };
        var result = await _paymentService.ProcessRefundAsync(refundDto);

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("cannot exceed total paid amount");
    }

    [Fact]
    public async Task OpenCashRegisterAsync_ValidFloat_CreatesOpenSession()
    {
        // Arrange
        var dto = new OpenCashRegisterDto
        {
            OpeningFloat = 1500.00m,
            Notes = "Morning shift opening float"
        };

        // Act
        var result = await _paymentService.OpenCashRegisterAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.OpeningFloat.Should().Be(1500.00m);
        result.Data.IsOpen.Should().BeTrue();
        result.Data.CashierUsername.Should().Be("cashier1");
    }

    [Fact]
    public async Task OpenCashRegisterAsync_AlreadyOpen_ReturnsFailure()
    {
        // Arrange: Open once
        await _paymentService.OpenCashRegisterAsync(new OpenCashRegisterDto { OpeningFloat = 1000m });

        // Act: Try to open again while open
        var result = await _paymentService.OpenCashRegisterAsync(new OpenCashRegisterDto { OpeningFloat = 500m });

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("already open");
    }

    [Fact]
    public async Task CloseCashRegisterAsync_ComputesExpectedCashAndDiscrepancy()
    {
        // Arrange: Open register with 1000 float
        await _paymentService.OpenCashRegisterAsync(new OpenCashRegisterDto { OpeningFloat = 1000m });

        // Process a cash payment of 500
        await _paymentService.ProcessPaymentAsync(new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 500.00m
        });

        // Expected cash = 1000 + 500 = 1500
        // Act: Cashier counts 1520 (+20 overage)
        var closeDto = new CloseCashRegisterDto
        {
            ActualCash = 1520.00m,
            Notes = "20 rupees excess change"
        };
        var result = await _paymentService.CloseCashRegisterAsync(closeDto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.IsOpen.Should().BeFalse();
        result.Data.ExpectedCash.Should().Be(1500.00m);
        result.Data.ActualCash.Should().Be(1520.00m);
        result.Data.Discrepancy.Should().Be(20.00m);
    }

    [Fact]
    public async Task GetPaymentReconciliationAsync_AggregatesTotalsByPaymentMode()
    {
        // Arrange: Open register with 1000
        await _paymentService.OpenCashRegisterAsync(new OpenCashRegisterDto { OpeningFloat = 1000m });

        // Process Cash payment of 200
        await _paymentService.ProcessPaymentAsync(new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.Cash,
            Amount = 200.00m
        });

        // Process UPI payment of 300
        await _paymentService.ProcessPaymentAsync(new ProcessPaymentDto
        {
            InvoiceId = 1,
            PaymentMode = PaymentMode.UPI,
            Amount = 300.00m,
            TransactionReference = "UPI-RECON-77"
        });

        // Act
        var result = await _paymentService.GetPaymentReconciliationAsync(_fixedNow);

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.OpeningFloat.Should().Be(1000.00m);
        result.Data.CashCollected.Should().Be(200.00m);
        result.Data.UpiCollected.Should().Be(300.00m);
        result.Data.NetCollected.Should().Be(500.00m);
        result.Data.ExpectedCashInDrawer.Should().Be(1200.00m);
        result.Data.TotalTransactions.Should().Be(2);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }
}
