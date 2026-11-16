using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class UserSessionConfiguration : IEntityTypeConfiguration<UserSession>
{
    public void Configure(EntityTypeBuilder<UserSession> builder)
    {
        builder.ToTable("UserSessions");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.SessionToken)
            .IsRequired()
            .HasMaxLength(128);

        builder.HasIndex(s => s.SessionToken)
            .IsUnique();

        builder.Property(s => s.DeviceId)
            .HasMaxLength(100);

        builder.Property(s => s.DeviceName)
            .HasMaxLength(150);

        builder.Property(s => s.IpAddress)
            .HasMaxLength(50);

        builder.Property(s => s.UserAgent)
            .HasMaxLength(300);

        builder.HasOne(s => s.User)
            .WithMany(u => u.Sessions)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

