using System.Security.Claims;
using BillingPOS.Domain.Entities;

namespace BillingPOS.Application.Interfaces;

public interface IJwtTokenService
{
    (string Token, DateTime ExpiresAtUtc) GenerateAccessToken(User user, string roleName, IEnumerable<string> permissions);
    RefreshToken GenerateRefreshToken(long userId, string? ipAddress = null);
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}

