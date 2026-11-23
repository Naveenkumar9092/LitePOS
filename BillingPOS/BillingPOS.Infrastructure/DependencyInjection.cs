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
        var databaseProvider = Environment.GetEnvironmentVariable("DatabaseProvider") 
            ?? configuration.GetValue<string>("DatabaseProvider") 
            ?? "PostgreSql";

        var defaultConn = configuration.GetConnectionString("DefaultConnection") 
            ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection") 
            ?? "";

        var sqliteConnection = configuration.GetConnectionString("SqliteConnection")
            ?? Environment.GetEnvironmentVariable("ConnectionStrings__SqliteConnection")
            ?? "Data Source=LitePOS_Local_Dev.db";

        var isPostgres = !string.IsNullOrEmpty(databaseUrl) ||
            string.Equals(databaseProvider, "PostgreSql", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(databaseProvider, "Postgres", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(databaseProvider, "Npgsql", StringComparison.OrdinalIgnoreCase) ||
            defaultConn.Contains("Host=", StringComparison.OrdinalIgnoreCase) ||
            defaultConn.Contains("supabase", StringComparison.OrdinalIgnoreCase) ||
            defaultConn.StartsWith("postgres", StringComparison.OrdinalIgnoreCase);

        var rawPostgresConn = !string.IsNullOrEmpty(databaseUrl)
            ? databaseUrl
            : (!string.IsNullOrEmpty(defaultConn) ? defaultConn : (configuration.GetConnectionString("PostgresConnection") ?? ""));

        const string verifiedNeonConnection = "Host=ep-lucky-wind-akv27p1t-pooler.c-3.us-west-2.aws.neon.tech;Port=5432;Database=neondb;Username=neondb_owner;Password=npg_yCjMZW5VkRh2;SSL Mode=Require;Trust Server Certificate=true;Pooling=true;KeepAlive=30;";

        var isPlaceholder = string.IsNullOrWhiteSpace(rawPostgresConn) ||
            rawPostgresConn.Contains("your-project-ref", StringComparison.OrdinalIgnoreCase) ||
            rawPostgresConn.Contains("YOUR_SUPABASE_PASSWORD", StringComparison.OrdinalIgnoreCase) ||
            rawPostgresConn.Contains("YOUR_DATABASE_PASSWORD", StringComparison.OrdinalIgnoreCase) ||
            rawPostgresConn.Contains("supabase", StringComparison.OrdinalIgnoreCase) ||
            rawPostgresConn.Contains("Trusted_Connection", StringComparison.OrdinalIgnoreCase) ||
            rawPostgresConn.Contains("MSSQLLocalDB", StringComparison.OrdinalIgnoreCase);

        if (isPlaceholder || string.IsNullOrWhiteSpace(rawPostgresConn) || rawPostgresConn.Contains("supabase", StringComparison.OrdinalIgnoreCase))
        {
            rawPostgresConn = verifiedNeonConnection;
            isPostgres = true;
            isPlaceholder = false;
        }

        if (isPostgres && !isPlaceholder)
        {
            var parsedPostgresConn = ParsePostgresConnectionString(rawPostgresConn);

            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseNpgsql(parsedPostgresConn, npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(BillingPOSDbContext).Assembly.FullName);
                    npgsqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 5,
                        maxRetryDelay: TimeSpan.FromSeconds(10),
                        errorCodesToAdd: null);
                }));
        }
        else if (string.Equals(databaseProvider, "Sqlite", StringComparison.OrdinalIgnoreCase) || isPlaceholder)
        {
            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseSqlite(sqliteConnection));
        }
        else
        {
            services.AddDbContext<BillingPOSDbContext>(options =>
                options.UseSqlServer(defaultConn, sqlOptions =>
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

        // 1. URI format: postgresql://[user]:[password]@[host]:[port]/[database]
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
                if (string.IsNullOrEmpty(database)) database = "postgres";

                var builder = new Npgsql.NpgsqlConnectionStringBuilder
                {
                    Host = host,
                    Port = port,
                    Database = database,
                    Username = username,
                    Password = password,
                    SslMode = Npgsql.SslMode.Require,
                    Pooling = true,
                    MaxPoolSize = 50,
                    MinPoolSize = 2,
                    KeepAlive = 30,
                    Timeout = 30,
                    CommandTimeout = 30
                };

                return builder.ConnectionString;
            }
            catch
            {
                return connectionOrUrl;
            }
        }

        // 2. Key-Value format: Host=...;Database=...;Username=...;Password=...
        try
        {
            var builder = new Npgsql.NpgsqlConnectionStringBuilder(connectionOrUrl)
            {
                SslMode = Npgsql.SslMode.Require,
                Pooling = true
            };

            if (builder.KeepAlive <= 0) builder.KeepAlive = 30;
            if (builder.Timeout <= 0) builder.Timeout = 30;
            if (builder.CommandTimeout <= 0) builder.CommandTimeout = 30;
            if (builder.MaxPoolSize <= 0) builder.MaxPoolSize = 50;

            return builder.ConnectionString;
        }
        catch
        {
            return connectionOrUrl;
        }
    }
}

