using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface ICategoryService
{
    Task<ApiResponse<List<CategoryDto>>> GetCategoriesAsync(bool? isActive = null, CancellationToken cancellationToken = default);
    Task<ApiResponse<CategoryDto>> GetCategoryByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<ApiResponse<CategoryDto>> CreateCategoryAsync(CreateCategoryDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<CategoryDto>> UpdateCategoryAsync(long id, UpdateCategoryDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> UpdateCategoryStatusAsync(long id, bool isActive, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> UpdateSortOrderAsync(UpdateCategorySortOrderDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> DeleteCategoryAsync(long id, CancellationToken cancellationToken = default);
}

