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
              .SetIsOriginAllowed(_ => true);
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseMiddleware<GlobalExceptionMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();

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

    if (dbContext.Database.IsSqlServer() || dbContext.Database.IsSqlite())
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
