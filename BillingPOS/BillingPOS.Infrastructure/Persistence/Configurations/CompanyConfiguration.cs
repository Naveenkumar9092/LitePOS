using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class CompanyConfiguration : IEntityTypeConfiguration<Company>
{
    public void Configure(EntityTypeBuilder<Company> builder)
    {
        builder.ToTable("Companies");

        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).ValueGeneratedOnAdd();

        builder.Property(c => c.CompanyName)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(c => c.LegalName)
            .HasMaxLength(200);

        builder.Property(c => c.BusinessType)
            .IsRequired();

        builder.Property(c => c.GSTIN)
            .HasMaxLength(15);

        builder.Property(c => c.PAN)
            .HasMaxLength(10);

        builder.Property(c => c.Email)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(c => c.MobileNumber)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(c => c.Website)
            .HasMaxLength(150);

        builder.Property(c => c.LogoStorageKey)
            .HasMaxLength(255);

        builder.Property(c => c.CreatedBy)
            .HasMaxLength(100);

        builder.Property(c => c.UpdatedBy)
            .HasMaxLength(100);

        // One-to-one relationship between Company and Shop
        builder.HasOne(c => c.Shop)
            .WithOne(s => s.Company)
            .HasForeignKey<Shop>(s => s.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

