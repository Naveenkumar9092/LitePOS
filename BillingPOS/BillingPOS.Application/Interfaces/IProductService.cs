using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IProductService
{
    Task<ApiResponse<ProductDto>> CreateProductAsync(CreateProductDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PagedProductsResultDto>> GetProductsAsync(int pageNumber = 1, int pageSize = 50, string? search = null, long? categoryId = null, bool? isAvailable = null, bool? isActive = null, CancellationToken cancellationToken = default);
    Task<ApiResponse<ProductDto>> GetProductByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<ApiResponse<ProductDto>> UpdateProductAsync(long id, UpdateProductDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> UpdateProductAvailabilityAsync(long id, bool isAvailable, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> UpdateProductStatusAsync(long id, bool isActive, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> UpdateProductImageAsync(long id, string imageStorageKey, CancellationToken cancellationToken = default);
    Task<ApiResponse<List<ProductSearchResultDto>>> SearchProductsAsync(string query, CancellationToken cancellationToken = default);
    Task<ApiResponse<List<CategoryDropdownDto>>> GetCategoriesDropdownAsync(CancellationToken cancellationToken = default);
}

