using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CategoriesController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    /// <summary>
    /// Gets all categories ordered by DisplayOrder.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<CategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories([FromQuery] bool? isActive, CancellationToken cancellationToken)
    {
        var response = await _categoryService.GetCategoriesAsync(isActive, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }
        return Ok(response);
    }

    /// <summary>
    /// Gets a category by its ID.
    /// </summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCategoryById(long id, CancellationToken cancellationToken)
    {
        var response = await _categoryService.GetCategoryByIdAsync(id, cancellationToken);
        if (!response.Success)
        {
            return NotFound(response);
        }
        return Ok(response);
    }

    /// <summary>
    /// Creates a new category.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryDto dto, CancellationToken cancellationToken)
    {
        var response = await _categoryService.CreateCategoryAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }
        return CreatedAtAction(nameof(GetCategoryById), new { id = response.Data!.CategoryId }, response);
    }

    /// <summary>
    /// Updates an existing category.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCategory(long id, [FromBody] UpdateCategoryDto dto, CancellationToken cancellationToken)
    {
        var response = await _categoryService.UpdateCategoryAsync(id, dto, cancellationToken);
        if (!response.Success)
        {
            if (response.Message == "Category not found.")
            {
                return NotFound(response);
            }
            return BadRequest(response);
        }
        return Ok(response);
    }

    /// <summary>
    /// Updates a category's active/inactive status.
    /// </summary>
    [HttpPatch("{id:long}/status")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCategoryStatus(long id, [FromBody] UpdateCategoryStatusDto dto, CancellationToken cancellationToken)
    {
        var response = await _categoryService.UpdateCategoryStatusAsync(id, dto.IsActive, cancellationToken);
        if (!response.Success)
        {
            if (response.Message == "Category not found.")
            {
                return NotFound(response);
            }
            return BadRequest(response);
        }
        return Ok(response);
    }

    /// <summary>
    /// Updates the display order of multiple categories in batch.
    /// </summary>
    [HttpPut("sort-order")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateSortOrder([FromBody] UpdateCategorySortOrderDto dto, CancellationToken cancellationToken)
    {
        var response = await _categoryService.UpdateSortOrderAsync(dto, cancellationToken);
        if (!response.Success)
        {
            return BadRequest(response);
        }
        return Ok(response);
    }

    /// <summary>
    /// Deletes a category if no products are assigned to it.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteCategory(long id, CancellationToken cancellationToken)
    {
        var response = await _categoryService.DeleteCategoryAsync(id, cancellationToken);
        if (!response.Success)
        {
            if (response.Message == "Category not found.")
            {
                return NotFound(response);
            }
            return BadRequest(response);
        }
        return Ok(response);
    }
}
