namespace BillingPOS.Domain.Interfaces;

public interface ICurrentUserService
{
    long? UserId { get; }
    string? Username { get; }
    string? Role { get; }
    long? ShopId { get; }
    long? CompanyId { get; }
    string? DeviceId { get; }
    bool IsAuthenticated { get; }
}

