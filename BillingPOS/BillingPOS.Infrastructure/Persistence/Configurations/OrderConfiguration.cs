using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("Orders");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.OrderNumber)
            .IsRequired()
            .HasMaxLength(50);

        builder.HasIndex(o => o.OrderNumber)
            .IsUnique();

        builder.Property(o => o.SubTotal)
            .HasPrecision(18, 2);

        builder.Property(o => o.DiscountAmount)
            .HasPrecision(18, 2);

        builder.Property(o => o.TaxAmount)
            .HasPrecision(18, 2);

        builder.Property(o => o.GrandTotal)
            .HasPrecision(18, 2);

        builder.Property(o => o.CashierUsername)
            .HasMaxLength(50);

        builder.HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

public class OrderDetailConfiguration : IEntityTypeConfiguration<OrderDetail>
{
    public void Configure(EntityTypeBuilder<OrderDetail> builder)
    {
        builder.ToTable("OrderDetails");

        builder.HasKey(od => od.Id);

        builder.Property(od => od.ProductNameSnapshot)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(od => od.UnitPrice)
            .HasPrecision(18, 2);

        builder.Property(od => od.DiscountAmount)
            .HasPrecision(18, 2);

        builder.Property(od => od.TaxPercentage)
            .HasPrecision(5, 2);

        builder.Property(od => od.TaxAmount)
            .HasPrecision(18, 2);

        builder.Property(od => od.LineTotal)
            .HasPrecision(18, 2);

        builder.HasOne(od => od.Order)
            .WithMany(o => o.Details)
            .HasForeignKey(od => od.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

