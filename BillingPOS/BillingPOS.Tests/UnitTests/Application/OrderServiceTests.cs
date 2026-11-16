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

public class OrderServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IOrderService _orderService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public OrderServiceTests()
    {
        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(1);
        _mockCurrentUserService.Setup(s => s.Username).Returns("cashier1");

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_OrderTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options, _mockDateTimeService.Object, _mockCurrentUserService.Object);

        SeedTestData();

        var orderRepo = new GenericRepository<Order>(_dbContext);
        var orderDetailRepo = new GenericRepository<OrderDetail>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var customerRepo = new GenericRepository<Customer>(_dbContext);
        var invoiceRepo = new GenericRepository<Invoice>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<OrderService>>();

        _orderService = new OrderService(
            orderRepo,
            orderDetailRepo,
            productRepo,
            customerRepo,
            invoiceRepo,
            unitOfWork,
            _mockCurrentUserService.Object,
            _mockDateTimeService.Object,
            new CreateOrderValidator(),
            new UpdateOrderStatusValidator(),
            new CancelOrderValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var category = new Category
        {
            Id = 1,
            CategoryName = "Hot Beverages",
            CategoryGuid = Guid.NewGuid(),
            IsActive = true
        };
        _dbContext.Categories.Add(category);

        var product1 = new Product
        {
            Id = 1,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Espresso",
            ProductGuid = Guid.NewGuid(),
            SellingPrice = 120.00m,
            TaxPercentage = 5.00m,
            IsAvailable = true,
            IsActive = true
        };

        var product2 = new Product
        {
            Id = 2,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Cappuccino",
            ProductGuid = Guid.NewGuid(),
            SellingPrice = 180.00m,
            TaxPercentage = 5.00m,
            IsAvailable = true,
            IsActive = true
        };

        var productUnavailable = new Product
        {
            Id = 3,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Seasonal Brew",
            ProductGuid = Guid.NewGuid(),
            SellingPrice = 250.00m,
            TaxPercentage = 18.00m,
            IsAvailable = false,
            IsActive = true
        };

        _dbContext.Products.AddRange(product1, product2, productUnavailable);

        var customer = new Customer
        {
            Id = 1,
            CustomerName = "John Doe",
            MobileNumber = "9876543210",
            CustomerGuid = Guid.NewGuid(),
            IsActive = true
        };
        _dbContext.Customers.Add(customer);

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateOrderAsync_ValidCounterSale_CalculatesTotalsAndSavesSuccessfully()
    {
        // Arrange
        var dto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, UnitPrice = 120.00m, TaxPercentage = 5.00m },
                new() { ProductId = 2, Quantity = 1, UnitPrice = 180.00m, TaxPercentage = 5.00m }
            }
        };

        // Act
        var result = await _orderService.CreateOrderAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.OrderNumber.Should().StartWith("ORD-20261113-");
        result.Data.OrderType.Should().Be(OrderType.CounterSale);
        result.Data.OrderStatus.Should().Be(OrderStatus.New);
        result.Data.CashierUsername.Should().Be("cashier1");

        // SubTotal: 2 * 120 + 1 * 180 = 240 + 180 = 420
        result.Data.SubTotal.Should().Be(420.00m);
        // Tax: 420 * 5% = 21.00
        result.Data.TaxAmount.Should().Be(21.00m);
        // GrandTotal: 420 + 21 = 441.00
        result.Data.GrandTotal.Should().Be(441.00m);
        result.Data.Details.Should().HaveCount(2);
    }

    [Fact]
    public async Task CreateOrderAsync_WithCustomerAndTakeaway_ReturnsSuccess()
    {
        // Arrange
        var dto = new CreateOrderDto
        {
            CustomerId = 1,
            OrderType = OrderType.Takeaway,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1, UnitPrice = 120.00m, TaxPercentage = 5.00m }
            }
        };

        // Act
        var result = await _orderService.CreateOrderAsync(dto);

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.CustomerId.Should().Be(1);
        result.Data.CustomerName.Should().Be("John Doe");
        result.Data.CustomerMobile.Should().Be("9876543210");
        result.Data.OrderType.Should().Be(OrderType.Takeaway);
    }

    [Fact]
    public async Task CreateOrderAsync_EmptyItems_ReturnsValidationError()
    {
        // Arrange
        var dto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto>()
        };

        // Act
        var result = await _orderService.CreateOrderAsync(dto);

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("Validation failed");
    }

    [Fact]
    public async Task CreateOrderAsync_UnavailableProduct_ReturnsFailure()
    {
        // Arrange
        var dto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 3, Quantity = 1, UnitPrice = 250.00m, TaxPercentage = 18.00m }
            }
        };

        // Act
        var result = await _orderService.CreateOrderAsync(dto);

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("unavailable");
    }

    [Fact]
    public async Task UpdateOrderStatusAsync_ValidTransitions_Success()
    {
        // Arrange: Create initial order (New)
        var createDto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1 }
            }
        };
        var created = await _orderService.CreateOrderAsync(createDto);
        var orderId = created.Data!.Id;

        // Act & Assert 1: New -> Confirmed
        var step1 = await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Confirmed });
        step1.Success.Should().BeTrue();
        step1.Data!.OrderStatus.Should().Be(OrderStatus.Confirmed);

        // Act & Assert 2: Confirmed -> Preparing
        var step2 = await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Preparing });
        step2.Success.Should().BeTrue();
        step2.Data!.OrderStatus.Should().Be(OrderStatus.Preparing);

        // Act & Assert 3: Preparing -> Ready
        var step3 = await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Ready });
        step3.Success.Should().BeTrue();
        step3.Data!.OrderStatus.Should().Be(OrderStatus.Ready);

        // Act & Assert 4: Ready -> Completed
        var step4 = await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Completed });
        step4.Success.Should().BeTrue();
        step4.Data!.OrderStatus.Should().Be(OrderStatus.Completed);
    }

    [Fact]
    public async Task UpdateOrderStatusAsync_InvalidTransition_ReturnsFailure()
    {
        // Arrange: Create initial order (New)
        var createDto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        };
        var created = await _orderService.CreateOrderAsync(createDto);
        var orderId = created.Data!.Id;

        // Act: Invalid transition: New -> Preparing (skipping Confirmed)
        var result = await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Preparing });

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("Invalid status transition");
    }

    [Fact]
    public async Task CancelOrderAsync_ActiveOrder_SetsStatusToCancelled()
    {
        // Arrange
        var createDto = new CreateOrderDto
        {
            OrderType = OrderType.Takeaway,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        };
        var created = await _orderService.CreateOrderAsync(createDto);
        var orderId = created.Data!.Id;

        // Act
        var result = await _orderService.CancelOrderAsync(orderId, new CancelOrderDto { Reason = "Customer changed mind" });

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.OrderStatus.Should().Be(OrderStatus.Cancelled);
        result.Data.UpdatedBy.Should().Contain("Customer changed mind");
    }

    [Fact]
    public async Task CancelOrderAsync_CompletedOrder_ReturnsFailure()
    {
        // Arrange: Create and complete order
        var createDto = new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        };
        var created = await _orderService.CreateOrderAsync(createDto);
        var orderId = created.Data!.Id;

        await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Confirmed });
        await _orderService.UpdateOrderStatusAsync(orderId, new UpdateOrderStatusDto { NewStatus = OrderStatus.Completed });

        // Act: Attempt to cancel completed order
        var result = await _orderService.CancelOrderAsync(orderId, new CancelOrderDto { Reason = "Mistake" });

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("already been completed");
    }

    [Fact]
    public async Task GetOrdersAsync_FilterByStatus_ReturnsOnlyMatching()
    {
        // Arrange: Create 2 orders, confirm 1
        var o1 = await _orderService.CreateOrderAsync(new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        });
        var o2 = await _orderService.CreateOrderAsync(new CreateOrderDto
        {
            OrderType = OrderType.Takeaway,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 2, Quantity = 1 } }
        });

        await _orderService.UpdateOrderStatusAsync(o1.Data!.Id, new UpdateOrderStatusDto { NewStatus = OrderStatus.Confirmed });

        // Act
        var result = await _orderService.GetOrdersAsync(new OrderFilterDto { Status = OrderStatus.Confirmed });

        // Assert
        result.Success.Should().BeTrue();
        result.Data!.Items.Should().HaveCount(1);
        result.Data.Items[0].Id.Should().Be(o1.Data.Id);
    }

    [Fact]
    public async Task GetOrderHistoryAsync_ReturnsOnlyCompletedAndCancelledOrders()
    {
        // Arrange
        var o1 = await _orderService.CreateOrderAsync(new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        });
        var o2 = await _orderService.CreateOrderAsync(new CreateOrderDto
        {
            OrderType = OrderType.Takeaway,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 2, Quantity = 1 } }
        });
        var o3 = await _orderService.CreateOrderAsync(new CreateOrderDto
        {
            OrderType = OrderType.CounterSale,
            Items = new List<CreateOrderItemDto> { new() { ProductId = 1, Quantity = 1 } }
        });

        // o1: Completed
        await _orderService.UpdateOrderStatusAsync(o1.Data!.Id, new UpdateOrderStatusDto { NewStatus = OrderStatus.Confirmed });
        await _orderService.UpdateOrderStatusAsync(o1.Data!.Id, new UpdateOrderStatusDto { NewStatus = OrderStatus.Completed });

        // o2: Cancelled
        await _orderService.CancelOrderAsync(o2.Data!.Id, new CancelOrderDto { Reason = "No stock" });

        // o3: Still New

        // Act
        var historyResult = await _orderService.GetOrderHistoryAsync(new OrderFilterDto());

        // Assert
        historyResult.Success.Should().BeTrue();
        historyResult.Data!.Items.Should().HaveCount(2);
        historyResult.Data.Items.Select(x => x.OrderStatus).Should().Contain(new[] { OrderStatus.Completed, OrderStatus.Cancelled });
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }
}
