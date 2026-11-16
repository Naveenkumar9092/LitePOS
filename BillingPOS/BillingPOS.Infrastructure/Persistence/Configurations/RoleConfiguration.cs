using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class RoleConfiguration : IEntityTypeConfiguration<Role>
{
    public void Configure(EntityTypeBuilder<Role> builder)
    {
        builder.ToTable("Roles");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Name)
            .IsRequired()
            .HasMaxLength(50);

        builder.HasIndex(r => r.Name)
            .IsUnique();

        builder.Property(r => r.Description)
            .HasMaxLength(250);

        builder.Property(r => r.IsActive)
            .IsRequired()
            .HasDefaultValue(true);

        builder.HasData(
            new Role { Id = 1, Name = "SAdmin", Description = "Super Administrator - Full system access", IsActive = true },
            new Role { Id = 2, Name = "Admin", Description = "Shop Administrator - Shop and catalog management", IsActive = true },
            new Role { Id = 3, Name = "Cashier", Description = "Billing Operator - POS orders and payment collection", IsActive = true }
        );
    }
}

