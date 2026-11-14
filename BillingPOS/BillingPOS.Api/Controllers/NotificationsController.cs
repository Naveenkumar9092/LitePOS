using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiController]
[Route("api/v1/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    /// <summary>
    /// Sends a branded HTML tax invoice via Email.
    /// </summary>
    [HttpPost("email/invoice")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<NotificationResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SendInvoiceEmail([FromBody] SendInvoiceNotificationDto dto, CancellationToken cancellationToken)
    {
        dto.Channel = NotificationChannel.Email;
        var result = await _notificationService.SendInvoiceEmailAsync(dto, cancellationToken);
        return Ok(ApiResponse<NotificationResultDto>.SuccessResult(result, result.Message));
    }

    /// <summary>
    /// Sends a formatted digital invoice via WhatsApp.
    /// </summary>
    [HttpPost("whatsapp/invoice")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<NotificationResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SendInvoiceWhatsApp([FromBody] SendInvoiceNotificationDto dto, CancellationToken cancellationToken)
    {
        dto.Channel = NotificationChannel.WhatsApp;
        var result = await _notificationService.SendInvoiceWhatsAppAsync(dto, cancellationToken);
        return Ok(ApiResponse<NotificationResultDto>.SuccessResult(result, result.Message));
    }

    /// <summary>
    /// Gets paged notification audit logs.
    /// </summary>
    [HttpGet("logs")]
    [Authorize(Roles = "SAdmin,Admin,Cashier")]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<NotificationAuditLogDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNotificationLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var result = await _notificationService.GetNotificationLogsAsync(page, pageSize, cancellationToken);
        return Ok(ApiResponse<PagedResult<NotificationAuditLogDto>>.SuccessResult(result, "Notification audit logs retrieved."));
    }
}

