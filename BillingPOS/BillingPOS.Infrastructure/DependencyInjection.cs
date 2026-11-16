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
        AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

        var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL") ?? configuration["DATABASE_URL"];
        var databaseProvider = configuration.GetValue<string>("DatabaseProvider");
        var sqlServerConnection = configuration.GetConnectionString("DefaultConnection") 
            ?? "Server=(localdb)\\MSSQLLocalDB;Database=LitePOS_BillingDb_Dev;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";

        var sqliteConnection = configuration.GetConnectionString("SqliteConnection")
            ?? "Data Source=LitePOS_Local_Dev.db";

        var isPostgres = !string.IsNullOrEmpty(databaseUrl) ||
            string.Equals(databaseProvider, "PostgreSql", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(databaseProvider, "Postgres", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(databaseProvider, "Npgsql", StringComparison.OrdinalIgnoreCase);

        if (isPostgres)
        {
            var rawPostgresConn = !string.IsNullOrEmpty(databaseUrl)
                ? databaseUrl
                : (configuration.GetConnectionString("PostgresConnection") ?? configuration.GetConnectionString("DefaultConnection") ?? "");

            var parsedPostgresConn = ParsePostgresConnectionString(rawPostgresConn);

            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseNpgsql(parsedPostgresConn, npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(BillingPOSDbContext).Assembly.FullName);
                    npgsqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 3,
                        maxRetryDelay: TimeSpan.FromSeconds(5),
                        errorCodesToAdd: null);
                }));
        }
        else if (string.Equals(databaseProvider, "Sqlite", StringComparison.OrdinalIgnoreCase))
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

    private static string ParsePostgresConnectionString(string connectionOrUrl)
    {
        if (string.IsNullOrWhiteSpace(connectionOrUrl)) return connectionOrUrl;

        if (connectionOrUrl.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) ||
            connectionOrUrl.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                var uri = new Uri(connectionOrUrl);
                var userInfo = uri.UserInfo.Split(':', 2);
                var username = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : "";
                var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : "";
                var host = uri.Host;
                var port = uri.Port > 0 ? uri.Port : 5432;
                var database = uri.AbsolutePath.TrimStart('/');

                var builder = new Npgsql.NpgsqlConnectionStringBuilder
                {
                    Host = host,
                    Port = port,
                    Database = database,
                    Username = username,
                    Password = password,
                    SslMode = Npgsql.SslMode.Prefer
                };

                return builder.ConnectionString;
            }
            catch
            {
                return connectionOrUrl;
            }
        }

        return connectionOrUrl;
    }
}

