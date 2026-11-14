using Asp.Versioning;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/products")]
[Authorize]
public class ProductsController : BaseApiController
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpPost]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductDto dto, CancellationToken cancellationToken)
    {
        var result = await _productService.CreateProductAsync(dto, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return CreatedAtAction(nameof(GetProductById), new { id = result.Data!.ProductId }, result);
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedProductsResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProducts(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? search = null,
        [FromQuery] long? categoryId = null,
        [FromQuery] bool? isAvailable = null,
        [FromQuery] bool? isActive = null,
        CancellationToken cancellationToken = default)
    {
        var result = await _productService.GetProductsAsync(pageNumber, pageSize, search, categoryId, isAvailable, isActive, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProductById(long id, CancellationToken cancellationToken)
    {
        var result = await _productService.GetProductByIdAsync(id, cancellationToken);
        if (!result.Success)
        {
            return NotFound(result);
        }

        return Ok(result);
    }

    [HttpPut("{id:long}")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateProduct(long id, [FromBody] UpdateProductDto dto, CancellationToken cancellationToken)
    {
        var result = await _productService.UpdateProductAsync(id, dto, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPatch("{id:long}/availability")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateAvailability(long id, [FromBody] UpdateProductAvailabilityDto dto, CancellationToken cancellationToken)
    {
        var result = await _productService.UpdateProductAvailabilityAsync(id, dto.IsAvailable, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPatch("{id:long}/status")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateStatus(long id, [FromBody] UpdateProductStatusDto dto, CancellationToken cancellationToken)
    {
        var result = await _productService.UpdateProductStatusAsync(id, dto.IsActive, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPost("{id:long}/image")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateImage(long id, [FromBody] ProductImageUploadDto dto, CancellationToken cancellationToken)
    {
        var result = await _productService.UpdateProductImageAsync(id, dto.ImageStorageKey, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpGet("search")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductSearchResultDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SearchProducts([FromQuery] string query, CancellationToken cancellationToken)
    {
        var result = await _productService.SearchProductsAsync(query, cancellationToken);
        return Ok(result);
    }

    [HttpGet("categories-dropdown")]
    [ProducesResponseType(typeof(ApiResponse<List<CategoryDropdownDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategoriesDropdown(CancellationToken cancellationToken)
    {
        var result = await _productService.GetCategoriesDropdownAsync(cancellationToken);
        return Ok(result);
    }
}

