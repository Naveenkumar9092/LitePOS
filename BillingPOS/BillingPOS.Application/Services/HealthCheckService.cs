using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using BillingPOS.Domain.Interfaces;

namespace BillingPOS.Application.Services;

public class HealthCheckService : IHealthCheckService
{
    private readonly IBillingPOSDbContext _dbContext;
    private readonly IDateTimeService _dateTimeService;

    public HealthCheckService(
        IBillingPOSDbContext dbContext,
        IDateTimeService dateTimeService)
    {
        _dbContext = dbContext;
        _dateTimeService = dateTimeService;
    }

    public async Task<HealthCheckDto> GetHealthStatusAsync(CancellationToken cancellationToken = default)
    {
        bool dbConnected = false;
        string? dbError = null;
        try
        {
            dbConnected = await _dbContext.CanConnectAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            dbConnected = false;
            dbError = ex.Message;
        }

        var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";

        return new HealthCheckDto
        {
            Status = dbConnected ? "Healthy" : "Degraded",
            Environment = environment,
            Version = AppConstants.AppVersion,
            ServerTimeUtc = _dateTimeService.UtcNow,
            DatabaseConnected = dbConnected,
            DatabaseProvider = _dbContext.ProviderName,
            DatabaseError = dbError
        };
    }
}
