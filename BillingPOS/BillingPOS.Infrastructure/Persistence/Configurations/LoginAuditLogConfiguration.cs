using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class LoginAuditLogConfiguration : IEntityTypeConfiguration<LoginAuditLog>
{
    public void Configure(EntityTypeBuilder<LoginAuditLog> builder)
    {
        builder.ToTable("LoginAuditLogs");

        builder.HasKey(l => l.Id);

        builder.Property(l => l.UsernameAttempted)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(l => l.IpAddress)
            .HasMaxLength(50);

        builder.Property(l => l.UserAgent)
            .HasMaxLength(300);

        builder.Property(l => l.DeviceId)
            .HasMaxLength(100);

        builder.Property(l => l.FailureReason)
            .HasMaxLength(250);

        builder.HasOne(l => l.User)
            .WithMany(u => u.AuditLogs)
            .HasForeignKey(l => l.UserId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

