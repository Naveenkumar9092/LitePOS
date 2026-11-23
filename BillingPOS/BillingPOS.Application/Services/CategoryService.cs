using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class CategoryService : ICategoryService
{
    private readonly IRepository<Category> _categoryRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<CreateCategoryDto> _createValidator;
    private readonly IValidator<UpdateCategoryDto> _updateValidator;
    private readonly IValidator<UpdateCategorySortOrderDto> _sortOrderValidator;
    private readonly ILogger<CategoryService> _logger;
    private readonly IMemoryCache? _cache;

    private const string CacheKeyAll = "categories_all";
    private const string CacheKeyActive = "categories_active";
    private const string CacheKeyInactive = "categories_inactive";

    private void InvalidateCache()
    {
        _cache?.Remove(CacheKeyAll);
        _cache?.Remove(CacheKeyActive);
        _cache?.Remove(CacheKeyInactive);
    }

    public CategoryService(
        IRepository<Category> categoryRepository,
        IRepository<Product> productRepository,
        IUnitOfWork unitOfWork,
        IDateTimeService dateTimeService,
        IValidator<CreateCategoryDto> createValidator,
        IValidator<UpdateCategoryDto> updateValidator,
        IValidator<UpdateCategorySortOrderDto> sortOrderValidator,
        ILogger<CategoryService> logger,
        IMemoryCache? cache = null)
    {
        _categoryRepository = categoryRepository;
        _productRepository = productRepository;
        _unitOfWork = unitOfWork;
        _dateTimeService = dateTimeService;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
        _sortOrderValidator = sortOrderValidator;
        _logger = logger;
        _cache = cache;
    }

    public async Task<ApiResponse<List<CategoryDto>>> GetCategoriesAsync(bool? isActive = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var cacheKey = isActive switch
            {
                true => CacheKeyActive,
                false => CacheKeyInactive,
                null => CacheKeyAll
            };

            if (_cache != null && _cache.TryGetValue(cacheKey, out List<CategoryDto>? cachedList) && cachedList != null)
            {
                return ApiResponse<List<CategoryDto>>.SuccessResult(cachedList);
            }

            var query = _categoryRepository.Query();
            if (isActive.HasValue)
            {
                query = query.Where(c => c.IsActive == isActive.Value);
            }

            var categories = await query
                .OrderBy(c => c.DisplayOrder)
                .ThenBy(c => c.CategoryName)
                .ToListAsync(cancellationToken);

            var productCounts = await _productRepository.Query()
                .GroupBy(p => p.CategoryId)
                .Select(g => new { CategoryId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CategoryId, x => x.Count, cancellationToken);

            var dtos = categories.Select(c => new CategoryDto(
                c.Id,
                c.CategoryGuid,
                c.CategoryName,
                c.Description,
                c.CategoryImageStorageKey,
                c.DisplayOrder,
                c.IsActive,
                productCounts.GetValueOrDefault(c.Id, 0),
                c.CreatedAtUtc,
                c.UpdatedAtUtc
            )).ToList();

            if (_cache != null)
            {
                _cache.Set(cacheKey, dtos, new MemoryCacheEntryOptions
                {
                    SlidingExpiration = TimeSpan.FromMinutes(15),
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1)
                });
            }

            return ApiResponse<List<CategoryDto>>.SuccessResult(dtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving categories");
            return ApiResponse<List<CategoryDto>>.FailureResult("An error occurred while retrieving categories.");
        }
    }

    public async Task<ApiResponse<CategoryDto>> GetCategoryByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var category = await _categoryRepository.GetByIdAsync(id, cancellationToken);
            if (category == null)
            {
                return ApiResponse<CategoryDto>.FailureResult("Category not found.");
            }

            var productCount = await _productRepository.Query()
                .CountAsync(p => p.CategoryId == id, cancellationToken);

            var dto = new CategoryDto(
                category.Id,
                category.CategoryGuid,
                category.CategoryName,
                category.Description,
                category.CategoryImageStorageKey,
                category.DisplayOrder,
                category.IsActive,
                productCount,
                category.CreatedAtUtc,
                category.UpdatedAtUtc
            );

            return ApiResponse<CategoryDto>.SuccessResult(dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving category with ID {CategoryId}", id);
            return ApiResponse<CategoryDto>.FailureResult("An error occurred while retrieving the category.");
        }
    }

    public async Task<ApiResponse<CategoryDto>> CreateCategoryAsync(CreateCategoryDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _createValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CategoryDto>.FailureResult("Validation failed.", errors);
            }

            var normalizedName = dto.CategoryName.Trim();
            var duplicateExists = await _categoryRepository.Query()
                .AnyAsync(c => c.CategoryName.ToLower() == normalizedName.ToLower(), cancellationToken);

            if (duplicateExists)
            {
                return ApiResponse<CategoryDto>.FailureResult($"A category named '{normalizedName}' already exists.");
            }

            int displayOrder = dto.DisplayOrder;
            if (displayOrder <= 0)
            {
                var maxOrder = await _categoryRepository.Query().MaxAsync(c => (int?)c.DisplayOrder, cancellationToken) ?? 0;
                displayOrder = maxOrder + 1;
            }

            var category = new Category
            {
                CategoryGuid = Guid.NewGuid(),
                CategoryName = normalizedName,
                Description = dto.Description?.Trim(),
                CategoryImageStorageKey = dto.CategoryImageStorageKey?.Trim(),
                DisplayOrder = displayOrder,
                IsActive = true,
                CreatedAtUtc = _dateTimeService.UtcNow
            };

            await _categoryRepository.AddAsync(category, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            InvalidateCache();

            _logger.LogInformation("Category '{CategoryName}' (ID: {CategoryId}) created successfully.", category.CategoryName, category.Id);

            var resultDto = new CategoryDto(
                category.Id,
                category.CategoryGuid,
                category.CategoryName,
                category.Description,
                category.CategoryImageStorageKey,
                category.DisplayOrder,
                category.IsActive,
                0,
                category.CreatedAtUtc,
                category.UpdatedAtUtc
            );

            return ApiResponse<CategoryDto>.SuccessResult(resultDto, "Category created successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating category '{CategoryName}'", dto.CategoryName);
            return ApiResponse<CategoryDto>.FailureResult("An error occurred while creating the category.");
        }
    }

    public async Task<ApiResponse<CategoryDto>> UpdateCategoryAsync(long id, UpdateCategoryDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _updateValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CategoryDto>.FailureResult("Validation failed.", errors);
            }

            var category = await _categoryRepository.GetByIdAsync(id, cancellationToken);
            if (category == null)
            {
                return ApiResponse<CategoryDto>.FailureResult("Category not found.");
            }

            var normalizedName = dto.CategoryName.Trim();
            var duplicateExists = await _categoryRepository.Query()
                .AnyAsync(c => c.Id != id && c.CategoryName.ToLower() == normalizedName.ToLower(), cancellationToken);

            if (duplicateExists)
            {
                return ApiResponse<CategoryDto>.FailureResult($"Another category named '{normalizedName}' already exists.");
            }

            category.CategoryName = normalizedName;
            category.Description = dto.Description?.Trim();
            category.CategoryImageStorageKey = dto.CategoryImageStorageKey?.Trim();
            category.DisplayOrder = dto.DisplayOrder;
            category.IsActive = dto.IsActive;
            category.UpdatedAtUtc = _dateTimeService.UtcNow;

            _categoryRepository.Update(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            InvalidateCache();

            var productCount = await _productRepository.Query()
                .CountAsync(p => p.CategoryId == id, cancellationToken);

            var resultDto = new CategoryDto(
                category.Id,
                category.CategoryGuid,
                category.CategoryName,
                category.Description,
                category.CategoryImageStorageKey,
                category.DisplayOrder,
                category.IsActive,
                productCount,
                category.CreatedAtUtc,
                category.UpdatedAtUtc
            );

            _logger.LogInformation("Category ID {CategoryId} updated successfully.", id);
            return ApiResponse<CategoryDto>.SuccessResult(resultDto, "Category updated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category with ID {CategoryId}", id);
            return ApiResponse<CategoryDto>.FailureResult("An error occurred while updating the category.");
        }
    }

    public async Task<ApiResponse<bool>> UpdateCategoryStatusAsync(long id, bool isActive, CancellationToken cancellationToken = default)
    {
        try
        {
            var category = await _categoryRepository.GetByIdAsync(id, cancellationToken);
            if (category == null)
            {
                return ApiResponse<bool>.FailureResult("Category not found.");
            }

            category.IsActive = isActive;
            category.UpdatedAtUtc = _dateTimeService.UtcNow;

            _categoryRepository.Update(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            InvalidateCache();

            _logger.LogInformation("Category ID {CategoryId} status set to {Status}.", id, isActive ? "Active" : "Inactive");
            return ApiResponse<bool>.SuccessResult(true, $"Category {(isActive ? "activated" : "deactivated")} successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling status for category ID {CategoryId}", id);
            return ApiResponse<bool>.FailureResult("An error occurred while updating category status.");
        }
    }

    public async Task<ApiResponse<bool>> UpdateSortOrderAsync(UpdateCategorySortOrderDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _sortOrderValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<bool>.FailureResult("Validation failed.", errors);
            }

            var categoryIds = dto.Items.Select(i => i.CategoryId).Distinct().ToList();
            var categories = await _categoryRepository.Query()
                .Where(c => categoryIds.Contains(c.Id))
                .ToListAsync(cancellationToken);

            var orderMap = dto.Items.ToDictionary(i => i.CategoryId, i => i.DisplayOrder);

            foreach (var category in categories)
            {
                if (orderMap.TryGetValue(category.Id, out var newOrder))
                {
                    category.DisplayOrder = newOrder;
                    category.UpdatedAtUtc = _dateTimeService.UtcNow;
                    _categoryRepository.Update(category);
                }
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            InvalidateCache();

            _logger.LogInformation("Updated display order for {Count} categories.", categories.Count);
            return ApiResponse<bool>.SuccessResult(true, "Category order updated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category sort orders");
            return ApiResponse<bool>.FailureResult("An error occurred while updating category sort order.");
        }
    }

    public async Task<ApiResponse<bool>> DeleteCategoryAsync(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var category = await _categoryRepository.GetByIdAsync(id, cancellationToken);
            if (category == null)
            {
                return ApiResponse<bool>.FailureResult("Category not found.");
            }

            var hasProducts = await _productRepository.Query()
                .AnyAsync(p => p.CategoryId == id, cancellationToken);

            if (hasProducts)
            {
                return ApiResponse<bool>.FailureResult("Cannot delete this category because products are assigned to it. Please deactivate the category instead.");
            }

            _categoryRepository.Remove(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            InvalidateCache();

            _logger.LogInformation("Category ID {CategoryId} deleted successfully.", id);
            return ApiResponse<bool>.SuccessResult(true, "Category deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting category ID {CategoryId}", id);
            return ApiResponse<bool>.FailureResult("An error occurred while deleting the category.");
        }
    }
}
