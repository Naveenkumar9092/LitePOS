using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.ProductName)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(p => p.Description)
            .HasMaxLength(500);

        builder.Property(p => p.ProductImageStorageKey)
            .HasMaxLength(255);

        builder.Property(p => p.SellingPrice)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(p => p.TaxPercentage)
            .HasPrecision(5, 2)
            .HasDefaultValue(0m);

        builder.Property(p => p.HSNCode)
            .HasMaxLength(20);

        builder.Property(p => p.IsAvailable)
            .HasDefaultValue(true);

        builder.Property(p => p.IsActive)
            .HasDefaultValue(true);

        builder.Property(p => p.CreatedAtUtc)
            .IsRequired();

        builder.HasIndex(p => p.ProductGuid)
            .IsUnique();

        builder.HasIndex(p => p.ProductName);

        builder.HasIndex(p => p.CategoryId);

        builder.HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(p => p.Company)
            .WithMany()
            .HasForeignKey(p => p.CompanyId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

