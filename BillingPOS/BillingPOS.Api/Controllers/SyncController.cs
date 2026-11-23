using BillingPOS.Api.Configuration;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/sync")]
[Authorize]
[EnableRateLimiting(RateLimiterConfiguration.SyncPolicy)]
public class SyncController : ControllerBase
{
    private readonly ISyncService _syncService;

    public SyncController(ISyncService syncService)
    {
        _syncService = syncService;
    }

    /// <summary>
    /// Registers or updates a POS terminal device heartbeat.
    /// </summary>
    [HttpPost("register-device")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<DeviceStatusDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceDto dto, CancellationToken cancellationToken)
    {
        var result = await _syncService.RegisterDeviceAsync(dto, cancellationToken);
        return Ok(ApiResponse<DeviceStatusDto>.SuccessResult(result, "Device registered successfully."));
    }

    /// <summary>
    /// Gets device heartbeat and sync metadata.
    /// </summary>
    [HttpGet("status")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<DeviceStatusDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDeviceStatus([FromQuery] string deviceId, CancellationToken cancellationToken)
    {
        var result = await _syncService.GetDeviceStatusAsync(deviceId, cancellationToken);
        if (result == null)
            return NotFound(ApiResponse.FailureResult("Device not found."));

        return Ok(ApiResponse<DeviceStatusDto>.SuccessResult(result, "Device status retrieved."));
    }

    /// <summary>
    /// Pushes a batch of offline invoices and customers to the server.
    /// </summary>
    [HttpPost("push")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<SyncPushResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> PushSyncBatch([FromBody] SyncPushRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _syncService.PushSyncBatchAsync(request, cancellationToken);
        return Ok(ApiResponse<SyncPushResultDto>.SuccessResult(result, "Sync push processed successfully."));
    }

    /// <summary>
    /// Pulls updated catalog (categories, products, taxes, configs, customers) from the server.
    /// </summary>
    [HttpPost("pull")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<SyncPullResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> PullSyncCatalog([FromBody] SyncPullRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _syncService.PullSyncCatalogAsync(request, cancellationToken);
        return Ok(ApiResponse<SyncPullResponseDto>.SuccessResult(result, "Sync pull completed successfully."));
    }

    /// <summary>
    /// Gets recent sync audit logs for auditing and diagnostic purposes.
    /// </summary>
    [HttpGet("history")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<List<SyncAuditLogDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSyncHistory([FromQuery] string? deviceId, [FromQuery] int limit = 20, CancellationToken cancellationToken = default)
    {
        var result = await _syncService.GetSyncHistoryAsync(deviceId, limit, cancellationToken);
        return Ok(ApiResponse<List<SyncAuditLogDto>>.SuccessResult(result, "Sync history retrieved."));
    }
}

