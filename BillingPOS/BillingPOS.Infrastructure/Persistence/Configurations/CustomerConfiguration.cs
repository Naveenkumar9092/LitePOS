using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("Customers");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.CustomerName)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(c => c.MobileNumber)
            .IsRequired()
            .HasMaxLength(20);

        builder.HasIndex(c => c.MobileNumber);

        builder.Property(c => c.WhatsAppNumber)
            .HasMaxLength(20);

        builder.Property(c => c.Email)
            .HasMaxLength(150);

        builder.Property(c => c.Address)
            .HasMaxLength(300);

        builder.Property(c => c.GSTIN)
            .HasMaxLength(15);
    }
}

