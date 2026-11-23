using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Infrastructure.Persistence.SQLServer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Infrastructure.Persistence;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(
        BillingPOSDbContext context, 
        IPasswordHasher passwordHasher, 
        ILogger logger, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            // First check if any company exists. If not, seed a default root company and shop
            var company = await context.Companies.Include(c => c.Shop).FirstOrDefaultAsync(cancellationToken);
            if (company == null)
            {
                company = new Company
                {
                    CompanyName = "LitePOS Retail Enterprises",
                    LegalName = "LitePOS Retail Enterprises Pvt Ltd",
                    BusinessType = BusinessType.Cafe,
                    GSTIN = "33AAAAA0000A1Z5",
                    PAN = "AAAAA0000A",
                    Email = "admin@litepos.com",
                    MobileNumber = "9840123456",
                    Website = "https://litepos.local",
                    LogoStorageKey = "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=200&auto=format&fit=crop&q=80",
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };

                var shop = new Shop
                {
                    Company = company,
                    ShopName = "LitePOS Main Store",
                    AddressLine1 = "42 Gandhi Road, T. Nagar",
                    City = "Chennai",
                    State = "Tamil Nadu",
                    Pincode = "600017",
                    Country = "India",
                    ContactNumber = "9840123456",
                    Email = "admin@litepos.com",
                    TimeZone = "India Standard Time",
                    CurrencyCode = "INR",
                    InvoiceHeader = "Welcome to LitePOS",
                    InvoiceFooter = "Thank you for shopping! Visit again.",
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };

                company.Shop = shop;
                await context.Companies.AddAsync(company, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded default Company and Shop.");
            }

            // Seed only the root sadmin user if none exists
            User? sadmin = await context.Users.FirstOrDefaultAsync(u => u.Username == "sadmin", cancellationToken);
            if (sadmin == null)
            {
                sadmin = new User
                {
                    CompanyId = company.Id,
                    ShopId = company.Shop?.Id,
                    FullName = "Super Administrator",
                    Username = "sadmin",
                    Email = "sadmin@litepos.com",
                    MobileNumber = "9876543210",
                    PasswordHash = passwordHasher.HashPassword("SAdmin@123!"),
                    RoleId = 1, // SAdmin
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };
                await context.Users.AddAsync(sadmin, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded root sadmin user.");
            }

            logger.LogInformation("Database verified with only root sadmin.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error while verifying database seeding.");
        }
    }
}
