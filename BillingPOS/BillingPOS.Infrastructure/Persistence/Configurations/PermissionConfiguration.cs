using BillingPOS.Application.Constants;
using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class PermissionConfiguration : IEntityTypeConfiguration<Permission>
{
    public void Configure(EntityTypeBuilder<Permission> builder)
    {
        builder.ToTable("Permissions");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Code)
            .IsRequired()
            .HasMaxLength(100);

        builder.HasIndex(p => p.Code)
            .IsUnique();

        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(p => p.Category)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(p => p.Description)
            .HasMaxLength(250);

        var seedPermissions = AppPermissions.AllPermissions
            .Select((p, idx) => new Permission
            {
                Id = idx + 1,
                Code = p.Code,
                Name = p.Name,
                Category = p.Category,
                Description = p.Description
            }).ToArray();

        builder.HasData(seedPermissions);
    }
}

