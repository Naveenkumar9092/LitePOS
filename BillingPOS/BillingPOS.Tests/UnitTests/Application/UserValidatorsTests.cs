using BillingPOS.Application.DTOs;
using BillingPOS.Application.Validators;
using Xunit;

namespace BillingPOS.Tests.UnitTests.Application;

public class UserValidatorsTests
{
    private readonly CreateUserValidator _createValidator = new();
    private readonly LoginRequestValidator _loginValidator = new();

    [Fact]
    public void CreateUserValidator_WithValidData_ShouldPass()
    {
        var model = new CreateUserDto(
            FullName: "Alice Bob",
            Username: "alice_pos",
            Email: "alice@example.com",
            MobileNumber: "9876543210",
            Password: "SecurePassword123!",
            RoleId: 3 // Cashier
        );

        var result = _createValidator.Validate(model);
        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("", "Username is required.")]
    [InlineData("ab", "Username must be between 3 and 50 characters.")]
    [InlineData("user with spaces", "Username can only contain letters, numbers, underscores, dots, and hyphens.")]
    public void CreateUserValidator_WithInvalidUsername_ShouldFail(string username, string expectedError)
    {
        var model = new CreateUserDto(
            FullName: "Alice",
            Username: username,
            Email: null,
            MobileNumber: null,
            Password: "Password123!",
            RoleId: 3
        );

        var result = _createValidator.Validate(model);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains(expectedError));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(4)]
    [InlineData(99)]
    public void CreateUserValidator_WithInvalidRoleId_ShouldFail(int roleId)
    {
        var model = new CreateUserDto(
            FullName: "Alice",
            Username: "alice_user",
            Email: null,
            MobileNumber: null,
            Password: "Password123!",
            RoleId: roleId
        );

        var result = _createValidator.Validate(model);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains("Invalid Role"));
    }

    [Fact]
    public void LoginRequestValidator_WithEmptyFields_ShouldFail()
    {
        var model = new LoginRequestDto("", "");
        var result = _loginValidator.Validate(model);

        Assert.False(result.IsValid);
        Assert.Equal(2, result.Errors.Count);
    }
}

