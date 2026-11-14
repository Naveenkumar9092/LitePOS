using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface ISyncService
{
    Task<DeviceStatusDto> RegisterDeviceAsync(RegisterDeviceDto dto, CancellationToken cancellationToken = default);
    Task<DeviceStatusDto?> GetDeviceStatusAsync(string deviceId, CancellationToken cancellationToken = default);
    Task<SyncPushResultDto> PushSyncBatchAsync(SyncPushRequestDto request, CancellationToken cancellationToken = default);
    Task<SyncPullResponseDto> PullSyncCatalogAsync(SyncPullRequestDto request, CancellationToken cancellationToken = default);
    Task<List<SyncAuditLogDto>> GetSyncHistoryAsync(string? deviceId = null, int limit = 20, CancellationToken cancellationToken = default);
}

