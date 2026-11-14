using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class CashRegisterConfiguration : IEntityTypeConfiguration<CashRegister>
{
    public void Configure(EntityTypeBuilder<CashRegister> builder)
    {
        builder.ToTable("CashRegisters");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.CashierUsername)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(c => c.DeviceId)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(c => c.OpeningFloat)
            .HasPrecision(18, 2);

        builder.Property(c => c.ActualCash)
            .HasPrecision(18, 2);

        builder.Property(c => c.ExpectedCash)
            .HasPrecision(18, 2);

        builder.Property(c => c.Discrepancy)
            .HasPrecision(18, 2);

        builder.Property(c => c.OpeningNotes)
            .HasMaxLength(500);

        builder.Property(c => c.ClosingNotes)
            .HasMaxLength(500);
    }
}

public class RefundConfiguration : IEntityTypeConfiguration<Refund>
{
    public void Configure(EntityTypeBuilder<Refund> builder)
    {
        builder.ToTable("Refunds");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Amount)
            .HasPrecision(18, 2);

        builder.Property(r => r.Reason)
            .IsRequired()
            .HasMaxLength(300);

        builder.Property(r => r.AuthorizedBy)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(r => r.ProcessedBy)
            .IsRequired()
            .HasMaxLength(100);

        builder.HasOne(r => r.Invoice)
            .WithMany()
            .HasForeignKey(r => r.InvoiceId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

