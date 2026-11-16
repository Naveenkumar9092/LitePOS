using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

public class HealthController : BaseApiController
{
    private readonly IHealthCheckService _healthCheckService;

    public HealthController(IHealthCheckService healthCheckService)
    {
        _healthCheckService = healthCheckService;
    }

    [HttpGet]
    public async Task<IActionResult> GetHealth(CancellationToken cancellationToken)
    {
        var status = await _healthCheckService.GetHealthStatusAsync(cancellationToken);
        return OkResponse(status, "System health retrieved successfully");
    }

    [HttpGet("ping")]
    public IActionResult Ping()
    {
        return OkResponse(new { Status = "Pong", Timestamp = DateTime.UtcNow }, "Pong response");
    }
}

