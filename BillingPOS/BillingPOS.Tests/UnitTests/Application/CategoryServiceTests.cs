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

public class CategoryServiceTests : IDisposable
{
    private readonly BillingPOSDbContext _dbContext;
    private readonly ICategoryService _categoryService;
    private readonly Mock<IDateTimeService> _mockDateTimeService;
    private readonly DateTime _fixedNow = new(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

    public CategoryServiceTests()
    {
        var options = new DbContextOptionsBuilder<BillingPOSDbContext>()
            .UseInMemoryDatabase(databaseName: $"BillingPOS_CategoryTest_{Guid.NewGuid()}")
            .Options;

        _dbContext = new BillingPOSDbContext(options);

        _mockDateTimeService = new Mock<IDateTimeService>();
        _mockDateTimeService.Setup(s => s.UtcNow).Returns(_fixedNow);

        SeedTestData();

        var categoryRepo = new GenericRepository<Category>(_dbContext);
        var productRepo = new GenericRepository<Product>(_dbContext);
        var unitOfWork = new UnitOfWork(_dbContext);
        var loggerMock = new Mock<ILogger<CategoryService>>();

        _categoryService = new CategoryService(
            categoryRepo,
            productRepo,
            unitOfWork,
            _mockDateTimeService.Object,
            new CreateCategoryValidator(),
            new UpdateCategoryValidator(),
            new UpdateCategorySortOrderValidator(),
            loggerMock.Object);
    }

    private void SeedTestData()
    {
        var categories = new List<Category>
        {
            new Category { Id = 1, CategoryGuid = Guid.NewGuid(), CategoryName = "Coffee", DisplayOrder = 1, IsActive = true, CreatedAtUtc = _fixedNow },
            new Category { Id = 2, CategoryGuid = Guid.NewGuid(), CategoryName = "Beverages", DisplayOrder = 2, IsActive = true, CreatedAtUtc = _fixedNow },
            new Category { Id = 3, CategoryGuid = Guid.NewGuid(), CategoryName = "Snacks", DisplayOrder = 3, IsActive = false, CreatedAtUtc = _fixedNow }
        };
        _dbContext.Categories.AddRange(categories);

        var products = new List<Product>
        {
            new Product { Id = 1, ProductGuid = Guid.NewGuid(), CategoryId = 1, CompanyId = 1, ProductName = "Espresso", SellingPrice = 120, IsAvailable = true, IsActive = true, CreatedAtUtc = _fixedNow },
            new Product { Id = 2, ProductGuid = Guid.NewGuid(), CategoryId = 1, CompanyId = 1, ProductName = "Cappuccino", SellingPrice = 150, IsAvailable = true, IsActive = true, CreatedAtUtc = _fixedNow }
        };
        _dbContext.Products.AddRange(products);

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetCategoriesAsync_ShouldReturnAllCategories_OrderedByDisplayOrder_WithProductCounts()
    {
        var result = await _categoryService.GetCategoriesAsync();

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Count.Should().Be(3);

        // Verify order
        result.Data[0].CategoryName.Should().Be("Coffee");
        result.Data[0].DisplayOrder.Should().Be(1);
        result.Data[0].ProductCount.Should().Be(2);

        result.Data[1].CategoryName.Should().Be("Beverages");
        result.Data[1].ProductCount.Should().Be(0);

        result.Data[2].CategoryName.Should().Be("Snacks");
        result.Data[2].IsActive.Should().BeFalse();
    }

    [Fact]
    public async Task GetCategoriesAsync_WithIsActiveFilter_ShouldFilterCorrectly()
    {
        var result = await _categoryService.GetCategoriesAsync(isActive: true);

        result.Success.Should().BeTrue();
        result.Data.Should().HaveCount(2);
        result.Data!.All(c => c.IsActive).Should().BeTrue();
    }

    [Fact]
    public async Task GetCategoryByIdAsync_ExistingId_ShouldReturnCategory()
    {
        var result = await _categoryService.GetCategoryByIdAsync(1);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.CategoryName.Should().Be("Coffee");
        result.Data.ProductCount.Should().Be(2);
    }

    [Fact]
    public async Task GetCategoryByIdAsync_NonExistingId_ShouldReturnNotFound()
    {
        var result = await _categoryService.GetCategoryByIdAsync(999);

        result.Success.Should().BeFalse();
        result.Message.Should().Be("Category not found.");
    }

    [Fact]
    public async Task CreateCategoryAsync_ValidData_ShouldCreateSuccessfully()
    {
        var dto = new CreateCategoryDto("Desserts", "Sweet treats and pastries", null, 4);

        var result = await _categoryService.CreateCategoryAsync(dto);

        result.Success.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.CategoryName.Should().Be("Desserts");
        result.Data.DisplayOrder.Should().Be(4);
        result.Data.ProductCount.Should().Be(0);

        var dbCategory = await _dbContext.Categories.FirstOrDefaultAsync(c => c.CategoryName == "Desserts");
        dbCategory.Should().NotBeNull();
        dbCategory!.IsActive.Should().BeTrue();
    }

    [Fact]
    public async Task CreateCategoryAsync_DuplicateName_ShouldReturnError()
    {
        var dto = new CreateCategoryDto("coffee", "Duplicate name test", null, 10);

        var result = await _categoryService.CreateCategoryAsync(dto);

        result.Success.Should().BeFalse();
        result.Message.Should().Contain("already exists");
    }

    [Fact]
    public async Task CreateCategoryAsync_EmptyName_ShouldFailValidation()
    {
        var dto = new CreateCategoryDto("", "No name", null, 1);

        var result = await _categoryService.CreateCategoryAsync(dto);

        result.Success.Should().BeFalse();
        result.Errors.Should().NotBeEmpty();
    }

    [Fact]
    public async Task UpdateCategoryAsync_ValidData_ShouldUpdateSuccessfully()
    {
        var dto = new UpdateCategoryDto("Specialty Coffee", "Freshly roasted single-origin", null, 1, true);

        var result = await _categoryService.UpdateCategoryAsync(1, dto);

        result.Success.Should().BeTrue();
        result.Data!.CategoryName.Should().Be("Specialty Coffee");

        var dbCategory = await _dbContext.Categories.FindAsync((long)1);
        dbCategory!.CategoryName.Should().Be("Specialty Coffee");
    }

    [Fact]
    public async Task UpdateCategoryAsync_DuplicateName_ShouldReturnError()
    {
        var dto = new UpdateCategoryDto("Beverages", "Renaming to existing category", null, 1, true);

        var result = await _categoryService.UpdateCategoryAsync(1, dto);

        result.Success.Should().BeFalse();
        result.Message.Should().Contain("already exists");
    }

    [Fact]
    public async Task UpdateCategoryStatusAsync_ShouldToggleStatus()
    {
        var result = await _categoryService.UpdateCategoryStatusAsync(1, false);

        result.Success.Should().BeTrue();

        var dbCategory = await _dbContext.Categories.FindAsync((long)1);
        dbCategory!.IsActive.Should().BeFalse();
    }

    [Fact]
    public async Task UpdateSortOrderAsync_ShouldUpdateDisplayOrders()
    {
        var dto = new UpdateCategorySortOrderDto(new List<CategorySortItemDto>
        {
            new CategorySortItemDto(1, 10),
            new CategorySortItemDto(2, 20)
        });

        var result = await _categoryService.UpdateSortOrderAsync(dto);

        result.Success.Should().BeTrue();

        var cat1 = await _dbContext.Categories.FindAsync((long)1);
        var cat2 = await _dbContext.Categories.FindAsync((long)2);
        cat1!.DisplayOrder.Should().Be(10);
        cat2!.DisplayOrder.Should().Be(20);
    }

    [Fact]
    public async Task DeleteCategoryAsync_CategoryWithProducts_ShouldFail()
    {
        // Category 1 has products
        var result = await _categoryService.DeleteCategoryAsync(1);

        result.Success.Should().BeFalse();
        result.Message.Should().Contain("Cannot delete this category because products are assigned to it");

        var dbCategory = await _dbContext.Categories.FindAsync((long)1);
        dbCategory.Should().NotBeNull();
    }

    [Fact]
    public async Task DeleteCategoryAsync_CategoryWithoutProducts_ShouldDeleteSuccessfully()
    {
        // Category 2 has no products
        var result = await _categoryService.DeleteCategoryAsync(2);

        result.Success.Should().BeTrue();

        var dbCategory = await _dbContext.Categories.FindAsync((long)2);
        dbCategory.Should().BeNull();
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}
