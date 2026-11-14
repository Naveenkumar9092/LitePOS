using BillingPOS.Application.Constants;
using BillingPOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BillingPOS.Infrastructure.Persistence.Configurations;

public class RolePermissionConfiguration : IEntityTypeConfiguration<RolePermission>
{
    public void Configure(EntityTypeBuilder<RolePermission> builder)
    {
        builder.ToTable("RolePermissions");

        builder.HasKey(rp => rp.Id);

        builder.HasIndex(rp => new { rp.RoleId, rp.PermissionId })
            .IsUnique();

        builder.HasOne(rp => rp.Role)
            .WithMany(r => r.RolePermissions)
            .HasForeignKey(rp => rp.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(rp => rp.Permission)
            .WithMany(p => p.RolePermissions)
            .HasForeignKey(rp => rp.PermissionId)
            .OnDelete(DeleteBehavior.Cascade);

        var allPermissions = AppPermissions.AllPermissions.Select((p, idx) => new { Id = idx + 1, p.Code }).ToList();
        var seedList = new List<RolePermission>();
        int idCounter = 1;

        // Role 1 (SAdmin): all permissions
        foreach (var p in allPermissions)
        {
            seedList.Add(new RolePermission { Id = idCounter++, RoleId = 1, PermissionId = p.Id });
        }

        // Role 2 (Admin): admin permissions
        foreach (var p in allPermissions.Where(p => AppPermissions.AdminPermissions.Contains(p.Code)))
        {
            seedList.Add(new RolePermission { Id = idCounter++, RoleId = 2, PermissionId = p.Id });
        }

        // Role 3 (Cashier): cashier permissions
        foreach (var p in allPermissions.Where(p => AppPermissions.CashierPermissions.Contains(p.Code)))
        {
            seedList.Add(new RolePermission { Id = idCounter++, RoleId = 3, PermissionId = p.Id });
        }

        builder.HasData(seedList);
    }
}

