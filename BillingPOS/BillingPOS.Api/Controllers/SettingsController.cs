using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/settings")]
[Authorize]
public class SettingsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public SettingsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    /// <summary>
    /// Gets application and store preferences.
    /// </summary>
    [HttpGet("preferences")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<ShopPreferenceDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPreferences(CancellationToken cancellationToken)
    {
        var result = await _notificationService.GetShopPreferencesAsync(cancellationToken);
        return Ok(ApiResponse<ShopPreferenceDto>.SuccessResult(result, "Shop preferences retrieved."));
    }

    /// <summary>
    /// Updates application and store preferences.
    /// </summary>
    [HttpPut("preferences")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<ShopPreferenceDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdatePreferences([FromBody] UpdateShopPreferenceDto dto, CancellationToken cancellationToken)
    {
        var result = await _notificationService.UpdateShopPreferencesAsync(dto, cancellationToken);
        return Ok(ApiResponse<ShopPreferenceDto>.SuccessResult(result, "Shop preferences updated successfully."));
    }

    /// <summary>
    /// Triggers an immediate database backup snapshot.
    /// </summary>
    [HttpPost("backup")]
    [Authorize(Roles = "SAdmin,Admin")]
    [ProducesResponseType(typeof(ApiResponse<DatabaseBackupResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateBackup(CancellationToken cancellationToken)
    {
        var result = await _notificationService.CreateDatabaseBackupAsync(cancellationToken);
        return Ok(ApiResponse<DatabaseBackupResultDto>.SuccessResult(result, result.Message));
    }

    /// <summary>
    /// Gets comprehensive system health and record count summary.
    /// </summary>
    [HttpGet("system-info")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<SystemInfoSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSystemInfo(CancellationToken cancellationToken)
    {
        var result = await _notificationService.GetSystemInfoAsync(cancellationToken);
        return Ok(ApiResponse<SystemInfoSummaryDto>.SuccessResult(result, "System info retrieved successfully."));
    }
}

