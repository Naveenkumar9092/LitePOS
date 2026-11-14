using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IHealthCheckService
{
    Task<HealthCheckDto> GetHealthStatusAsync(CancellationToken cancellationToken = default);
}

