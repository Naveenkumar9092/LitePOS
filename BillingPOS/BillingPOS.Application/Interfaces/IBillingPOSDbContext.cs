namespace BillingPOS.Application.Interfaces;

public interface IBillingPOSDbContext
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task<bool> CanConnectAsync(CancellationToken cancellationToken = default);
    string ProviderName { get; }
}

