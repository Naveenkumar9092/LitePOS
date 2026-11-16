using BillingPOS.Domain.Entities;
using FluentAssertions;

namespace BillingPOS.Tests.UnitTests.Domain;

public class TestAuditableEntity : AuditableEntity<long>
{
    public string Name { get; set; } = string.Empty;
}

public class BaseEntityTests
{
    [Fact]
    public void AuditableEntity_ShouldInitializeWithDefaultValues()
    {
        // Act
        var entity = new TestAuditableEntity
        {
            Id = 1,
            Name = "Test"
        };

        // Assert
        entity.Id.Should().Be(1);
        entity.Name.Should().Be("Test");
        entity.IsActive.Should().BeTrue();
        entity.CreatedAtUtc.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
        entity.UpdatedAtUtc.Should().BeNull();
        entity.CreatedBy.Should().BeNull();
        entity.UpdatedBy.Should().BeNull();
    }
}

