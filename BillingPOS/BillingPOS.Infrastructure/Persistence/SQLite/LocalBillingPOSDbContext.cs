using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BillingPOS.Infrastructure.Persistence.SQLite;

public class LocalBillingPOSDbContext : DbContext, IBillingPOSDbContext
{
    private readonly IDateTimeService? _dateTimeService;
    private readonly ICurrentUserService? _currentUserService;

    public LocalBillingPOSDbContext(DbContextOptions<LocalBillingPOSDbContext> options)
        : base(options)
    {
    }

    public LocalBillingPOSDbContext(
        DbContextOptions<LocalBillingPOSDbContext> options,
        IDateTimeService dateTimeService,
        ICurrentUserService currentUserService)
        : base(options)
    {
        _dateTimeService = dateTimeService;
        _currentUserService = currentUserService;
    }

    public DbSet<Company> Companies => Set<Company>();
    public DbSet<Shop> Shops => Set<Shop>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderDetail> OrderDetails => Set<OrderDetail>();
    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<InvoiceItem> InvoiceItems => Set<InvoiceItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Device> Devices => Set<Device>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();

    public string ProviderName => Database.ProviderName ?? "SQLite";

    public async Task<bool> CanConnectAsync(CancellationToken cancellationToken = default)
    {
        return await Database.CanConnectAsync(cancellationToken);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService?.UtcNow ?? DateTime.UtcNow;
        var currentUserId = _currentUserService?.Username ?? "LocalCashier";

        foreach (var entry in ChangeTracker.Entries<IAuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAtUtc = now;
                    entry.Entity.CreatedBy ??= currentUserId;
                    break;

                case EntityState.Modified:
                    entry.Entity.UpdatedAtUtc = now;
                    entry.Entity.UpdatedBy = currentUserId;
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }
}

