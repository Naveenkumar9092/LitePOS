namespace BillingPOS.Application.DTOs;

public record ProductDto(
    long ProductId,
    Guid ProductGuid,
    long CompanyId,
    long CategoryId,
    string CategoryName,
    string ProductName,
    string? Description,
    string? ProductImageStorageKey,
    decimal SellingPrice,
    long? TaxId,
    decimal TaxPercentage,
    string? HSNCode,
    bool IsAvailable,
    bool IsActive,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);

public record CreateProductDto(
    long CategoryId,
    string ProductName,
    string? Description,
    string? ProductImageStorageKey,
    decimal SellingPrice,
    long? TaxId,
    decimal TaxPercentage,
    string? HSNCode,
    bool IsAvailable = true
);

public record UpdateProductDto(
    long CategoryId,
    string ProductName,
    string? Description,
    string? ProductImageStorageKey,
    decimal SellingPrice,
    long? TaxId,
    decimal TaxPercentage,
    string? HSNCode,
    bool IsAvailable
);

public record UpdateProductAvailabilityDto(
    bool IsAvailable
);

public record UpdateProductStatusDto(
    bool IsActive
);

public record ProductImageUploadDto(
    string ImageStorageKey
);

public record ProductSearchResultDto(
    long ProductId,
    Guid ProductGuid,
    long CategoryId,
    string CategoryName,
    string ProductName,
    decimal SellingPrice,
    decimal TaxPercentage,
    string? HSNCode,
    string? ProductImageStorageKey,
    bool IsAvailable
);

public record CategoryDropdownDto(
    long CategoryId,
    string CategoryName,
    int DisplayOrder
);

public record PagedProductsResultDto(
    List<ProductDto> Items,
    int TotalCount,
    int PageNumber,
    int PageSize
);

