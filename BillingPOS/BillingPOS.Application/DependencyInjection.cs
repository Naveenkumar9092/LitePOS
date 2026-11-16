using BillingPOS.Application.Interfaces;
using BillingPOS.Application.Services;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace BillingPOS.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);
        services.AddScoped<IHealthCheckService, HealthCheckService>();
        services.AddScoped<ICompanyService, CompanyService>();
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IBillingService, BillingService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IGstService, GstService>();
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<ISyncService, SyncService>();
        services.AddScoped<IHardwareService, HardwareService>();

        return services;
    }
}

