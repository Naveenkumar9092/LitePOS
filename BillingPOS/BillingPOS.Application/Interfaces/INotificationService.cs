using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface INotificationService
{
    Task<NotificationResultDto> SendInvoiceEmailAsync(SendInvoiceNotificationDto dto, CancellationToken cancellationToken = default);
    Task<NotificationResultDto> SendInvoiceWhatsAppAsync(SendInvoiceNotificationDto dto, CancellationToken cancellationToken = default);
    Task<PagedResult<NotificationAuditLogDto>> GetNotificationLogsAsync(int page, int pageSize, CancellationToken cancellationToken = default);
    Task<ShopPreferenceDto> GetShopPreferencesAsync(CancellationToken cancellationToken = default);
    Task<ShopPreferenceDto> UpdateShopPreferencesAsync(UpdateShopPreferenceDto dto, CancellationToken cancellationToken = default);
    Task<DatabaseBackupResultDto> CreateDatabaseBackupAsync(CancellationToken cancellationToken = default);
    Task<SystemInfoSummaryDto> GetSystemInfoAsync(CancellationToken cancellationToken = default);
}

