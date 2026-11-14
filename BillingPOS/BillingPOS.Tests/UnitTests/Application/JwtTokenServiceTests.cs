using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BillingPOS.Domain.Entities;
using BillingPOS.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace BillingPOS.Tests.UnitTests.Application;

public class JwtTokenServiceTests
{
    private readonly JwtTokenService _tokenService;

    public JwtTokenServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["JwtSettings:Secret"] = "TestSuperSecretKeyForBillingAppDevelopment1234567890!",
                ["JwtSettings:Issuer"] = "LitePOS.Api",
                ["JwtSettings:Audience"] = "LitePOS.Client",
                ["JwtSettings:AccessTokenExpirationMinutes"] = "60",
                ["JwtSettings:RefreshTokenExpirationDays"] = "7"
            })
            .Build();

        _tokenService = new JwtTokenService(config);
    }

    [Fact]
    public void GenerateAccessToken_ShouldContainRequiredClaims()
    {
        var user = new User
        {
            Id = 42,
            CompanyId = 1,
            ShopId = 10,
            FullName = "John Doe",
            Username = "johndoe",
            Email = "john@example.com",
            MobileNumber = "9876543210"
        };
        var permissions = new[] { "billing.create", "orders.view" };

        var (token, expiresAtUtc) = _tokenService.GenerateAccessToken(user, "Cashier", permissions);

        Assert.NotNull(token);
        Assert.True(expiresAtUtc > DateTime.UtcNow);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        var nameClaim = jwt.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Name || c.Type == "unique_name" || c.Type == "name");
        Assert.NotNull(nameClaim);
        Assert.Equal("johndoe", nameClaim.Value);

        var roleClaim = jwt.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Role || c.Type == "role");
        Assert.NotNull(roleClaim);
        Assert.Equal("Cashier", roleClaim.Value);
        Assert.Equal("42", jwt.Claims.First(c => c.Type == "userId").Value);
        Assert.Equal("1", jwt.Claims.First(c => c.Type == "companyId").Value);
        Assert.Equal("10", jwt.Claims.First(c => c.Type == "shopId").Value);

        var permClaims = jwt.Claims.Where(c => c.Type == "permission").Select(c => c.Value).ToList();
        Assert.Contains("billing.create", permClaims);
        Assert.Contains("orders.view", permClaims);
    }

    [Fact]
    public void GenerateRefreshToken_ShouldReturnUnexpiredActiveToken()
    {
        var refreshToken = _tokenService.GenerateRefreshToken(42, "127.0.0.1");

        Assert.NotNull(refreshToken.Token);
        Assert.True(refreshToken.Token.Length > 20);
        Assert.Equal(42, refreshToken.UserId);
        Assert.Equal("127.0.0.1", refreshToken.CreatedByIp);
        Assert.True(refreshToken.IsActive);
        Assert.False(refreshToken.IsExpired);
        Assert.False(refreshToken.IsRevoked);
    }
}
