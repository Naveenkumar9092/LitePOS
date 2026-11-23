using BillingPOS.Api.Configuration;
using BillingPOS.Api.Middleware;
using BillingPOS.Application;
using BillingPOS.Application.Interfaces;
using BillingPOS.Infrastructure;
using BillingPOS.Infrastructure.Persistence;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using Microsoft.EntityFrameworkCore;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Load .env.local or .env from workspace or output directories if present
var possibleEnvFiles = new[]
{
    Path.Combine(Directory.GetCurrentDirectory(), ".env.local"),
    Path.Combine(Directory.GetCurrentDirectory(), ".env"),
    Path.Combine(Directory.GetParent(Directory.GetCurrentDirectory())?.FullName ?? "", ".env.local"),
    Path.Combine(Directory.GetParent(Directory.GetCurrentDirectory())?.FullName ?? "", ".env"),
    Path.Combine(Directory.GetParent(Directory.GetParent(Directory.GetCurrentDirectory())?.FullName ?? "")?.FullName ?? "", ".env.local"),
    Path.Combine(AppContext.BaseDirectory, ".env.local"),
    Path.Combine(AppContext.BaseDirectory, ".env")
};

foreach (var envFile in possibleEnvFiles)
{
    if (File.Exists(envFile))
    {
        foreach (var line in File.ReadAllLines(envFile))
        {
            var trimmed = line.Trim();
            if (string.IsNullOrWhiteSpace(trimmed) || trimmed.StartsWith("#")) continue;
            var parts = trimmed.Split('=', 2);
            if (parts.Length == 2)
            {
                var key = parts[0].Trim();
                var val = parts[1].Trim().Trim('"', '\'');
                if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(key)))
                {
                    Environment.SetEnvironmentVariable(key, val);
                }
            }
        }
        break;
    }
}

// Support Render / Cloud container PORT environment variable
var port = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(port))
{
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
}

// Configure Serilog
SerilogConfiguration.ConfigureSerilog(builder.Host);

// Add services to the container
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddCustomAuthentication(builder.Configuration);
builder.Services.AddCustomApiVersioning();
builder.Services.AddCustomSwagger();
builder.Services.AddCustomRateLimiting();
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
});

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
    });

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy", policy =>
    {
        policy.AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials()
              .SetIsOriginAllowed(_ => true)
              .SetPreflightMaxAge(TimeSpan.FromHours(24));
    });
});

var app = builder.Build();

app.UseResponseCompression();

// Configure Reverse Proxy Forwarded Headers (Render, Cloudflare, Nginx)
var forwardedHeadersOptions = new ForwardedHeadersOptions
{
    ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto
};
forwardedHeadersOptions.KnownIPNetworks.Clear();
forwardedHeadersOptions.KnownProxies.Clear();
app.UseForwardedHeaders(forwardedHeadersOptions);

// Configure the HTTP request pipeline
app.UseMiddleware<GlobalExceptionMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseRateLimiter();

var enableSwagger = app.Environment.IsDevelopment() 
    || app.Environment.IsEnvironment("Staging") 
    || builder.Configuration.GetValue<bool>("EnableSwagger", true);

if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Billing POS API v1");
        c.RoutePrefix = "swagger";
    });
}

if (!app.Environment.IsProduction() || builder.Configuration.GetValue<bool>("UseHttpsRedirection", false))
{
    app.UseHttpsRedirection();
}

app.UseCors("CorsPolicy");

var uploadsDir = Path.Combine(app.Environment.ContentRootPath, "uploads");
if (!Directory.Exists(uploadsDir))
{
    Directory.CreateDirectory(uploadsDir);
}
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsDir),
    RequestPath = "/uploads"
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Ensure Database is initialized and seeded
try
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<BillingPOSDbContext>();
    var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    if (dbContext.Database.IsSqlServer() || dbContext.Database.IsSqlite() || dbContext.Database.IsNpgsql())
    {
        await dbContext.Database.EnsureCreatedAsync();
        var shouldSeed = !app.Environment.IsProduction() || builder.Configuration.GetValue<bool>("SeedDatabaseOnStartup", true);
        if (shouldSeed)
        {
            await DatabaseSeeder.SeedAsync(dbContext, passwordHasher, logger);
        }
    }
}
catch (Exception ex)
{
    Log.Warning(ex, "Could not ensure database was migrated/seeded during initial startup. It will be verified on connection.");
}

Log.Information("LitePOS Web API starting up in {Environment} mode...", app.Environment.EnvironmentName);

app.Run();

// Make the implicit Program class public for integration test WebApplicationFactory
public partial class Program { }
