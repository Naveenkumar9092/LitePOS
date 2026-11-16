using BillingPOS.Application.Services;
using Xunit;

namespace BillingPOS.Tests.UnitTests.Application;

public class PasswordHasherTests
{
    private readonly PasswordHasher _hasher = new();

    [Fact]
    public void HashPassword_ShouldReturnValidFormattedHash()
    {
        var password = "SecurePassword123!";
        var hash = _hasher.HashPassword(password);

        Assert.NotNull(hash);
        Assert.StartsWith("pbkdf2-sha256$100000$", hash);
        Assert.NotEqual(password, hash);
    }

    [Fact]
    public void VerifyPassword_WithCorrectPassword_ShouldReturnTrue()
    {
        var password = "CashierSecret@2026";
        var hash = _hasher.HashPassword(password);

        var isValid = _hasher.VerifyPassword(password, hash);

        Assert.True(isValid);
    }

    [Fact]
    public void VerifyPassword_WithWrongPassword_ShouldReturnFalse()
    {
        var password = "CorrectPassword123";
        var hash = _hasher.HashPassword(password);

        var isValid = _hasher.VerifyPassword("WrongPassword456", hash);

        Assert.False(isValid);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    [InlineData("invalid-hash")]
    [InlineData("pbkdf2-sha256$notanumber$salt$hash")]
    public void VerifyPassword_WithMalformedHash_ShouldReturnFalse(string? malformedHash)
    {
        var isValid = _hasher.VerifyPassword("anypassword", malformedHash!);
        Assert.False(isValid);
    }
}

