using BillingPOS.Application.DTOs;
using FluentAssertions;

namespace BillingPOS.Tests.UnitTests.Application;

public class ApiResponseTests
{
    [Fact]
    public void SuccessResult_WithData_ShouldSetPropertiesProperly()
    {
        // Arrange
        var testData = new { Name = "Espresso", Price = 120m };

        // Act
        var response = ApiResponse<object>.SuccessResult(testData, "Fetched successfully");

        // Assert
        response.Success.Should().BeTrue();
        response.Message.Should().Be("Fetched successfully");
        response.Data.Should().Be(testData);
        response.Errors.Should().BeNull();
    }

    [Fact]
    public void FailureResult_ShouldSetErrorsProperly()
    {
        // Act
        var errors = new List<string> { "Invalid input", "Email format incorrect" };
        var response = ApiResponse.FailureResult("Validation failed", errors);

        // Assert
        response.Success.Should().BeFalse();
        response.Message.Should().Be("Validation failed");
        response.Data.Should().BeNull();
        response.Errors.Should().BeEquivalentTo(errors);
    }
}

