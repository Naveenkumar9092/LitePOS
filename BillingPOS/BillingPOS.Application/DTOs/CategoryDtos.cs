namespace BillingPOS.Application.DTOs;

public record CategoryDto(
    long CategoryId,
    Guid CategoryGuid,
    string CategoryName,
    string? Description,
    string? CategoryImageStorageKey,
    int DisplayOrder,
    bool IsActive,
    int ProductCount,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);

public record CreateCategoryDto(
    string CategoryName,
    string? Description,
    string? CategoryImageStorageKey,
    int DisplayOrder = 0
);

public record UpdateCategoryDto(
    string CategoryName,
    string? Description,
    string? CategoryImageStorageKey,
    int DisplayOrder,
    bool IsActive
);

public record UpdateCategoryStatusDto(
    bool IsActive
);

public record CategorySortItemDto(
    long CategoryId,
    int DisplayOrder
);

public record UpdateCategorySortOrderDto(
    List<CategorySortItemDto> Items
);

