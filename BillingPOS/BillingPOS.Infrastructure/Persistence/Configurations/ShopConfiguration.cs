using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class ShopConfiguration : IEntityTypeConfiguration<Shop>
{
    public void Configure(EntityTypeBuilder<Shop> builder)
    {
        builder.ToTable("Shops");

        builder.HasKey(s => s.Id);
        builder.Property(s => s.Id).ValueGeneratedOnAdd();

        builder.Property(s => s.ShopName)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(s => s.AddressLine1)
            .IsRequired()
            .HasMaxLength(250);

        builder.Property(s => s.AddressLine2)
            .HasMaxLength(250);

        builder.Property(s => s.City)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.State)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.Pincode)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(s => s.Country)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.ContactNumber)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(s => s.Email)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.TimeZone)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.CurrencyCode)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(s => s.InvoiceHeader)
            .HasMaxLength(500);

        builder.Property(s => s.InvoiceFooter)
            .HasMaxLength(500);

        builder.Property(s => s.CreatedBy)
            .HasMaxLength(100);

        builder.Property(s => s.UpdatedBy)
            .HasMaxLength(100);
    }
}

