using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using BillingPOS.Application.Validators;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using BillingPOS.Infrastructure.Repositories;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class ProductServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly IProductService _productService;
    private readonly Mock<ICurrentUserService> _mockCurrentUserService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public ProductServiceTests()
    {
        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_ProductTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options);

        _mockCurrentUserService = new Mock<ICurrentUserService>();
        _mockCurrentUserService.Setup(s => s.UserId).Returns(2);
        _mockCurrentUserService.Setup(s => s.CompanyId).Returns(1);

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        SeedTestData();

        var productRepo = new GenericRepository<Product>(_dbContext);
        var categoryRepo = new GenericRepository<Category>(_dbContext);
        var companyRepo = new GenericRepository<Company>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<ProductService>>();

        _productService = new ProductService(
            productRepo,
            categoryRepo,
            companyRepo,
            unitOfWork,
            _mockCurrentUserService.Object,
            _mockDateTimeService.Object,
            new CreateProductValidator(),
            new UpdateProductValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var company = new Company
        {
            Id = 1,
            CompanyName = "LitePOS Test Cafe",
            Email = "cafe@test.com",
            MobileNumber = "9876543210",
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Companies.Add(company);

        var coffeeCat = new Category
        {
            Id = 1,
            CategoryName = "Coffee",
            DisplayOrder = 1,
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };

        var snackCat = new Category
        {
            Id = 2,
            CategoryName = "Snacks",
            DisplayOrder = 2,
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };
        _dbContext.Categories.AddRange(coffeeCat, snackCat);

        var prod1 = new Product
        {
            Id = 1,
            CompanyId = 1,
            CategoryId = 1,
            ProductName = "Cappuccino",
            SellingPrice = 120.00m,
            TaxPercentage = 5.0m,
            HSNCode = "0901",
            IsAvailable = true,
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };

        var prod2 = new Product
        {
            Id = 2,
            CompanyId = 1,
            CategoryId = 2,
            ProductName = "Sandwich",
            SellingPrice = 100.00m,
            TaxPercentage = 5.0m,
            HSNCode = "1905",
            IsAvailable = false, // Out of stock
            IsActive = true,
            CreatedAtUtc = _fixedNow
        };

        _dbContext.Products.AddRange(prod1, prod2);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateProductAsync_Valid_CreatesProductWithSinglePrice()
    {
        var dto = new CreateProductDto(
            CategoryId: 1,
            ProductName: "Espresso",
            Description: "Strong single shot",
            ProductImageStorageKey: null,
            SellingPrice: 80.00m,
            TaxId: null,
            TaxPercentage: 5.0m,
            HSNCode: "0901",
            IsAvailable: true
        );

        var result = await _productService.CreateProductAsync(dto);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.ProductName.Should().Be("Espresso");
        result.Data.SellingPrice.Should().Be(80.00m);
        result.Data.CategoryName.Should().Be("Coffee");
        result.Data.IsAvailable.Should().BeTrue();
    }

    [Fact]
    public async Task CreateProductAsync_DuplicateName_ReturnsFailure()
    {
        var dto = new CreateProductDto(
            CategoryId: 1,
            ProductName: "Cappuccino",
            Description: "Duplicate",
            ProductImageStorageKey: null,
            SellingPrice: 130.00m,
            TaxId: null,
            TaxPercentage: 5.0m,
            HSNCode: "0901"
        );

        var result = await _productService.CreateProductAsync(dto);

        result.Success.Should().BeFalse();
        result.Message.Should().Contain("already exists");
    }

    [Fact]
    public async Task CreateProductAsync_InvalidPriceZero_ReturnsValidationFailure()
    {
        var dto = new CreateProductDto(
            CategoryId: 1,
            ProductName: "Free Coffee",
            Description: null,
            ProductImageStorageKey: null,
            SellingPrice: 0.00m, // Invalid: must be > 0
            TaxId: null,
            TaxPercentage: 5.0m,
            HSNCode: null
        );

        var result = await _productService.CreateProductAsync(dto);

        result.Success.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("greater than zero"));
    }

    [Fact]
    public async Task GetProductsAsync_FiltersByCategory()
    {
        var result = await _productService.GetProductsAsync(categoryId: 2);

        result.Success.Should().BeTrue();
        result.Data!.Items.Should().ContainSingle();
        result.Data.Items.First().ProductName.Should().Be("Sandwich");
    }

    [Fact]
    public async Task GetProductsAsync_FiltersByAvailability()
    {
        var result = await _productService.GetProductsAsync(isAvailable: true);

        result.Success.Should().BeTrue();
        result.Data!.Items.Should().ContainSingle();
        result.Data.Items.First().ProductName.Should().Be("Cappuccino");
    }

    [Fact]
    public async Task UpdateProductAsync_UpdatesSellingPriceAndMetadata()
    {
        var dto = new UpdateProductDto(
            CategoryId: 1,
            ProductName: "Premium Cappuccino",
            Description: "Rich artisanal espresso with foam",
            ProductImageStorageKey: null,
            SellingPrice: 140.00m,
            TaxId: null,
            TaxPercentage: 5.0m,
            HSNCode: "0901",
            IsAvailable: true
        );

        var result = await _productService.UpdateProductAsync(1, dto);

        result.Success.Should().BeTrue();
        result.Data!.ProductName.Should().Be("Premium Cappuccino");
        result.Data.SellingPrice.Should().Be(140.00m);
    }

    [Fact]
    public async Task UpdateProductAvailabilityAsync_TogglesAvailability()
    {
        var result = await _productService.UpdateProductAvailabilityAsync(1, false);

        result.Success.Should().BeTrue();
        var updated = await _productService.GetProductByIdAsync(1);
        updated.Data!.IsAvailable.Should().BeFalse();
    }

    [Fact]
    public async Task SearchProductsAsync_ReturnsMatchingProducts()
    {
        var result = await _productService.SearchProductsAsync("capp");

        result.Success.Should().BeTrue();
        result.Data.Should().ContainSingle();
        result.Data!.First().ProductName.Should().Be("Cappuccino");
    }

    [Fact]
    public async Task GetCategoriesDropdownAsync_ReturnsCategories()
    {
        var result = await _productService.GetCategoriesDropdownAsync();

        result.Success.Should().BeTrue();
        result.Data.Should().HaveCount(2);
        result.Data!.First().CategoryName.Should().Be("Coffee");
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}
