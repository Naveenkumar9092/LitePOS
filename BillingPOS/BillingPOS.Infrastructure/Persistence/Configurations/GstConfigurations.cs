using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class TaxConfiguration : IEntityTypeConfiguration<Tax>
{
    public void Configure(EntityTypeBuilder<Tax> builder)
    {
        builder.ToTable("Taxes");
        builder.HasKey(t => t.Id);

        builder.Property(t => t.TaxName).IsRequired().HasMaxLength(100);
        builder.Property(t => t.RatePercentage).HasPrecision(5, 2);
        builder.Property(t => t.CgstPercentage).HasPrecision(5, 2);
        builder.Property(t => t.SgstPercentage).HasPrecision(5, 2);
        builder.Property(t => t.IgstPercentage).HasPrecision(5, 2);
    }
}

public class HsnSacConfiguration : IEntityTypeConfiguration<HsnSac>
{
    public void Configure(EntityTypeBuilder<HsnSac> builder)
    {
        builder.ToTable("HsnSacs");
        builder.HasKey(h => h.Id);

        builder.Property(h => h.Code).IsRequired().HasMaxLength(20);
        builder.Property(h => h.Description).IsRequired().HasMaxLength(300);
        builder.Property(h => h.Type).IsRequired().HasMaxLength(10);
        builder.Property(h => h.DefaultGstRate).HasPrecision(5, 2);
    }
}

public class GstConfigConfiguration : IEntityTypeConfiguration<GstConfiguration>
{
    public void Configure(EntityTypeBuilder<GstConfiguration> builder)
    {
        builder.ToTable("GstConfigurations");
        builder.HasKey(g => g.Id);

        builder.Property(g => g.GSTIN).IsRequired().HasMaxLength(20);
        builder.Property(g => g.LegalName).IsRequired().HasMaxLength(150);
        builder.Property(g => g.TradeName).IsRequired().HasMaxLength(150);
        builder.Property(g => g.StateName).IsRequired().HasMaxLength(100);
        builder.Property(g => g.StateCode).IsRequired().HasMaxLength(5);
        builder.Property(g => g.InvoiceTermsAndConditions).HasMaxLength(1000);
        builder.Property(g => g.InvoiceHeader).HasMaxLength(500);
        builder.Property(g => g.InvoiceFooter).HasMaxLength(500);
    }
}

public class CreditNoteConfiguration : IEntityTypeConfiguration<CreditNote>
{
    public void Configure(EntityTypeBuilder<CreditNote> builder)
    {
        builder.ToTable("CreditNotes");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.CreditNoteNumber).IsRequired().HasMaxLength(50);
        builder.HasIndex(c => c.CreditNoteNumber).IsUnique();

        builder.Property(c => c.InvoiceNumberSnapshot).IsRequired().HasMaxLength(50);
        builder.Property(c => c.CustomerNameSnapshot).HasMaxLength(150);
        builder.Property(c => c.CustomerGstinSnapshot).HasMaxLength(20);
        builder.Property(c => c.Reason).IsRequired().HasMaxLength(300);
        builder.Property(c => c.NoteType).IsRequired().HasMaxLength(20);
        builder.Property(c => c.Status).IsRequired().HasMaxLength(30);

        builder.Property(c => c.TaxableAmount).HasPrecision(18, 2);
        builder.Property(c => c.CgstAmount).HasPrecision(18, 2);
        builder.Property(c => c.SgstAmount).HasPrecision(18, 2);
        builder.Property(c => c.IgstAmount).HasPrecision(18, 2);
        builder.Property(c => c.TotalTaxAmount).HasPrecision(18, 2);
        builder.Property(c => c.GrandTotal).HasPrecision(18, 2);

        builder.HasMany(c => c.Items)
            .WithOne(i => i.CreditNote)
            .HasForeignKey(i => i.CreditNoteId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class CreditNoteItemConfiguration : IEntityTypeConfiguration<CreditNoteItem>
{
    public void Configure(EntityTypeBuilder<CreditNoteItem> builder)
    {
        builder.ToTable("CreditNoteItems");
        builder.HasKey(i => i.Id);

        builder.Property(i => i.ProductNameSnapshot).IsRequired().HasMaxLength(150);
        builder.Property(i => i.HSNCodeSnapshot).HasMaxLength(20);
        builder.Property(i => i.Reason).HasMaxLength(200);

        builder.Property(i => i.UnitPrice).HasPrecision(18, 2);
        builder.Property(i => i.TaxPercentage).HasPrecision(5, 2);
        builder.Property(i => i.TaxAmount).HasPrecision(18, 2);
        builder.Property(i => i.LineTotal).HasPrecision(18, 2);
    }
}

