namespace BillingPOS.Domain.Interfaces;

public interface IDateTimeService
{
    DateTime UtcNow { get; }
    DateTime Now { get; }
}

