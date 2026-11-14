using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using BillingPOS.Domain.Constants;
using BillingPOS.Domain.Interfaces;
using FluentAssertions;
using Moq;

namespace BillingPOS.Tests.UnitTests.Application;

public class HealthCheckServiceTests
{
    private readonly Mock<IBillingPOSDbContext> _dbContextMock = new();
    private readonly Mock<IDateTimeService> _dateTimeServiceMock = new();

    public HealthCheckServiceTests()
    {
        _dateTimeServiceMock.Setup(d => d.UtcNow).Returns(new DateTime(2026, 1, 1, 12, 0, 0, DateTimeKind.Utc));
        _dbContextMock.Setup(d => d.ProviderName).Returns("Microsoft.EntityFrameworkCore.SqlServer");
    }

    [Fact]
    public async Task GetHealthStatusAsync_WhenDbCanConnect_ReturnsHealthyStatus()
    {
        // Arrange
        _dbContextMock.Setup(d => d.CanConnectAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var service = new HealthCheckService(_dbContextMock.Object, _dateTimeServiceMock.Object);

        // Act
        var result = await service.GetHealthStatusAsync();

        // Assert
        result.Status.Should().Be("Healthy");
        result.DatabaseConnected.Should().BeTrue();
        result.Version.Should().Be(AppConstants.AppVersion);
        result.DatabaseProvider.Should().Be("Microsoft.EntityFrameworkCore.SqlServer");
    }

    [Fact]
    public async Task GetHealthStatusAsync_WhenDbFails_ReturnsDegradedStatus()
    {
        // Arrange
        _dbContextMock.Setup(d => d.CanConnectAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var service = new HealthCheckService(_dbContextMock.Object, _dateTimeServiceMock.Object);

        // Act
        var result = await service.GetHealthStatusAsync();

        // Assert
        result.Status.Should().Be("Degraded");
        result.DatabaseConnected.Should().BeFalse();
    }
}

