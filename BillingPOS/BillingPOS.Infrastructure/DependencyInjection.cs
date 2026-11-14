using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Interfaces;
using BillingPOS.Infrastructure.Persistence.SQLite;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using BillingPOS.Infrastructure.Repositories;
using BillingPOS.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BillingPOS.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        var databaseProvider = configuration.GetValue<string>("DatabaseProvider") ?? "SqlServer";
        var sqlServerConnection = configuration.GetConnectionString("DefaultConnection") 
            ?? "Server=(localdb)\\MSSQLLocalDB;Database=LitePOS_BillingDb_Dev;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";

        var sqliteConnection = configuration.GetConnectionString("SqliteConnection")
            ?? "Data Source=LitePOS_Local_Dev.db";

        if (databaseProvider.Equals("Sqlite", StringComparison.OrdinalIgnoreCase))
        {
            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseSqlite(sqliteConnection));
        }
        else
        {
            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseSqlServer(sqlServerConnection, sqlOptions =>
                {
                    sqlOptions.MigrationsAssembly(typeof(BillingPOSDbContext).Assembly.FullName);
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 3,
                        maxRetryDelay: TimeSpan.FromSeconds(5),
                        errorNumbersToAdd: null);
                }));
        }

        services.AddDbContext<LocalBillingPOSDbContext>(options =>
            options.UseSqlite(sqliteConnection));

        services.AddScoped<IBillingPOSDbContext>(provider => 
            provider.GetRequiredService<BillingPOSDbContext>());

        services.AddScoped(typeof(IRepository<,>), typeof(GenericRepository<,>));
        services.AddScoped(typeof(IRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<IJwtTokenService, JwtTokenService>();

        services.AddSingleton<IDateTimeService, DateTimeService>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddHttpContextAccessor();

        return services;
    }
}

