using System.Security.Claims;
using BillingPOS.Domain.Interfaces;
using Microsoft.AspNetCore.Http;

namespace BillingPOS.Infrastructure.Services;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    private ClaimsPrincipal? User => _httpContextAccessor.HttpContext?.User;

    public long? UserId
    {
        get
        {
            var idClaim = User?.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                          ?? User?.FindFirst("sub")?.Value 
                          ?? User?.FindFirst("userId")?.Value;
            return long.TryParse(idClaim, out var id) ? id : null;
        }
    }

    public string? Username => User?.FindFirst(ClaimTypes.Name)?.Value 
                               ?? User?.FindFirst("username")?.Value;

    public string? Role => User?.FindFirst(ClaimTypes.Role)?.Value 
                           ?? User?.FindFirst("role")?.Value;

    public long? ShopId
    {
        get
        {
            var shopIdClaim = User?.FindFirst("shopId")?.Value;
            return long.TryParse(shopIdClaim, out var id) ? id : null;
        }
    }

    public long? CompanyId
    {
        get
        {
            var companyIdClaim = User?.FindFirst("companyId")?.Value;
            return long.TryParse(companyIdClaim, out var id) ? id : null;
        }
    }

    public string? DeviceId => _httpContextAccessor.HttpContext?.Request.Headers["X-Device-Id"].FirstOrDefault()
                               ?? User?.FindFirst("deviceId")?.Value;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated ?? false;
}

