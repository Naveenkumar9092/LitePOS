using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class ProductService : IProductService
{
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Category> _categoryRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<CreateProductDto> _createValidator;
    private readonly IValidator<UpdateProductDto> _updateValidator;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IRepository<Product> productRepository,
        IRepository<Category> categoryRepository,
        IRepository<Company> companyRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService,
        IValidator<CreateProductDto> createValidator,
        IValidator<UpdateProductDto> updateValidator,
        ILogger<ProductService> logger)
    {
        _productRepository = productRepository;
        _categoryRepository = categoryRepository;
        _companyRepository = companyRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
        _logger = logger;
    }

    public async Task<ApiResponse<ProductDto>> CreateProductAsync(CreateProductDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _createValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
        {
            var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
            return ApiResponse<ProductDto>.FailureResult("Validation failed.", errors);
        }

        // Check if category exists
        var category = await _categoryRepository.GetByIdAsync(dto.CategoryId, cancellationToken);
        if (category == null)
        {
            return ApiResponse<ProductDto>.FailureResult("The selected category does not exist.");
        }

        // Get single company ID (Single Company constraint)
        var company = await _companyRepository.Query().FirstOrDefaultAsync(cancellationToken);
        long companyId = company?.Id ?? _currentUserService.CompanyId ?? 1;

        // Check for duplicate product name within the active products
        var exists = await _productRepository.Query()
            .AnyAsync(p => p.ProductName.ToLower() == dto.ProductName.ToLower().Trim() && p.IsActive, cancellationToken);
        if (exists)
        {
            return ApiResponse<ProductDto>.FailureResult($"An active product named '{dto.ProductName}' already exists.");
        }

        var product = new Product
        {
            ProductGuid = Guid.NewGuid(),
            CompanyId = companyId,
            CategoryId = dto.CategoryId,
            ProductName = dto.ProductName.Trim(),
            Description = dto.Description?.Trim(),
            ProductImageStorageKey = dto.ProductImageStorageKey,
            SellingPrice = dto.SellingPrice,
            TaxId = dto.TaxId,
            TaxPercentage = dto.TaxPercentage,
            HSNCode = dto.HSNCode?.Trim(),
            IsAvailable = dto.IsAvailable,
            IsActive = true,
            CreatedAtUtc = _dateTimeService.UtcNow
        };

        await _productRepository.AddAsync(product, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Product '{ProductName}' (ID: {ProductId}) registered successfully with single price {SellingPrice}", product.ProductName, product.Id, product.SellingPrice);

        return ApiResponse<ProductDto>.SuccessResult(MapToDto(product, category.CategoryName), "Product created successfully.");
    }

    public async Task<ApiResponse<PagedProductsResultDto>> GetProductsAsync(
        int pageNumber = 1,
        int pageSize = 50,
        string? search = null,
        long? categoryId = null,
        bool? isAvailable = null,
        bool? isActive = null,
        CancellationToken cancellationToken = default)
    {
        var query = _productRepository.Query().Include(p => p.Category).AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.ProductName.ToLower().Contains(s) || (p.HSNCode != null && p.HSNCode.ToLower().Contains(s)));
        }

        if (categoryId.HasValue && categoryId.Value > 0)
        {
            query = query.Where(p => p.CategoryId == categoryId.Value);
        }

        if (isAvailable.HasValue)
        {
            query = query.Where(p => p.IsAvailable == isAvailable.Value);
        }

        if (isActive.HasValue)
        {
            query = query.Where(p => p.IsActive == isActive.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(p => p.Category.DisplayOrder)
            .ThenBy(p => p.ProductName)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(p => MapToDto(p, p.Category.CategoryName))
            .ToListAsync(cancellationToken);

        var result = new PagedProductsResultDto(items, totalCount, pageNumber, pageSize);
        return ApiResponse<PagedProductsResultDto>.SuccessResult(result, "Products retrieved successfully.");
    }

    public async Task<ApiResponse<ProductDto>> GetProductByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var product = await _productRepository.Query()
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (product == null)
        {
            return ApiResponse<ProductDto>.FailureResult("Product not found.");
        }

        return ApiResponse<ProductDto>.SuccessResult(MapToDto(product, product.Category?.CategoryName ?? ""), "Product details retrieved.");
    }

    public async Task<ApiResponse<ProductDto>> UpdateProductAsync(long id, UpdateProductDto dto, CancellationToken cancellationToken = default)
    {
        var validation = await _updateValidator.ValidateAsync(dto, cancellationToken);
        if (!validation.IsValid)
        {
            var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
            return ApiResponse<ProductDto>.FailureResult("Validation failed.", errors);
        }

        var product = await _productRepository.Query()
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (product == null)
        {
            return ApiResponse<ProductDto>.FailureResult("Product not found.");
        }

        var category = await _categoryRepository.GetByIdAsync(dto.CategoryId, cancellationToken);
        if (category == null)
        {
            return ApiResponse<ProductDto>.FailureResult("The selected category does not exist.");
        }

        // Check for duplicate name if changed
        if (product.ProductName.ToLower() != dto.ProductName.ToLower().Trim())
        {
            var duplicate = await _productRepository.Query()
                .AnyAsync(p => p.Id != id && p.ProductName.ToLower() == dto.ProductName.ToLower().Trim() && p.IsActive, cancellationToken);
            if (duplicate)
            {
                return ApiResponse<ProductDto>.FailureResult($"Another active product named '{dto.ProductName}' already exists.");
            }
        }

        product.CategoryId = dto.CategoryId;
        product.ProductName = dto.ProductName.Trim();
        product.Description = dto.Description?.Trim();
        product.ProductImageStorageKey = dto.ProductImageStorageKey;
        product.SellingPrice = dto.SellingPrice;
        product.TaxId = dto.TaxId;
        product.TaxPercentage = dto.TaxPercentage;
        product.HSNCode = dto.HSNCode?.Trim();
        product.IsAvailable = dto.IsAvailable;
        product.UpdatedAtUtc = _dateTimeService.UtcNow;

        _productRepository.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Product ID {ProductId} updated successfully.", id);

        return ApiResponse<ProductDto>.SuccessResult(MapToDto(product, category.CategoryName), "Product updated successfully.");
    }

    public async Task<ApiResponse<bool>> UpdateProductAvailabilityAsync(long id, bool isAvailable, CancellationToken cancellationToken = default)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product == null)
        {
            return ApiResponse<bool>.FailureResult("Product not found.");
        }

        product.IsAvailable = isAvailable;
        product.UpdatedAtUtc = _dateTimeService.UtcNow;
        _productRepository.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Product ID {ProductId} availability changed to {IsAvailable}.", id, isAvailable);
        return ApiResponse<bool>.SuccessResult(true, $"Product availability updated to {(isAvailable ? "Available" : "Unavailable")}.");
    }

    public async Task<ApiResponse<bool>> UpdateProductStatusAsync(long id, bool isActive, CancellationToken cancellationToken = default)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product == null)
        {
            return ApiResponse<bool>.FailureResult("Product not found.");
        }

        product.IsActive = isActive;
        product.UpdatedAtUtc = _dateTimeService.UtcNow;
        _productRepository.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Product ID {ProductId} active status changed to {IsActive}.", id, isActive);
        return ApiResponse<bool>.SuccessResult(true, $"Product status updated to {(isActive ? "Active" : "Inactive")}.");
    }

    public async Task<ApiResponse<bool>> UpdateProductImageAsync(long id, string imageStorageKey, CancellationToken cancellationToken = default)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product == null)
        {
            return ApiResponse<bool>.FailureResult("Product not found.");
        }

        product.ProductImageStorageKey = imageStorageKey;
        product.UpdatedAtUtc = _dateTimeService.UtcNow;
        _productRepository.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Product ID {ProductId} image key updated.", id);
        return ApiResponse<bool>.SuccessResult(true, "Product image updated successfully.");
    }

    public async Task<ApiResponse<List<ProductSearchResultDto>>> SearchProductsAsync(string query, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return ApiResponse<List<ProductSearchResultDto>>.SuccessResult([], "Query is empty.");
        }

        var s = query.Trim().ToLower();
        var products = await _productRepository.Query()
            .Include(p => p.Category)
            .AsNoTracking()
            .Where(p => p.IsActive && (p.ProductName.ToLower().Contains(s) || (p.HSNCode != null && p.HSNCode.ToLower().Contains(s))))
            .OrderBy(p => p.ProductName)
            .Take(20)
            .Select(p => new ProductSearchResultDto(
                p.Id,
                p.ProductGuid,
                p.CategoryId,
                p.Category.CategoryName,
                p.ProductName,
                p.SellingPrice,
                p.TaxPercentage,
                p.HSNCode,
                p.ProductImageStorageKey,
                p.IsAvailable
            ))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<ProductSearchResultDto>>.SuccessResult(products, "Search results retrieved.");
    }

    public async Task<ApiResponse<List<CategoryDropdownDto>>> GetCategoriesDropdownAsync(CancellationToken cancellationToken = default)
    {
        var categories = await _categoryRepository.Query()
            .AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.CategoryName)
            .Select(c => new CategoryDropdownDto(c.Id, c.CategoryName, c.DisplayOrder))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<CategoryDropdownDto>>.SuccessResult(categories, "Categories retrieved.");
    }

    private static ProductDto MapToDto(Product p, string categoryName)
    {
        return new ProductDto(
            p.Id,
            p.ProductGuid,
            p.CompanyId,
            p.CategoryId,
            categoryName,
            p.ProductName,
            p.Description,
            p.ProductImageStorageKey,
            p.SellingPrice,
            p.TaxId,
            p.TaxPercentage,
            p.HSNCode,
            p.IsAvailable,
            p.IsActive,
            p.CreatedAtUtc,
            p.UpdatedAtUtc
        );
    }
}
