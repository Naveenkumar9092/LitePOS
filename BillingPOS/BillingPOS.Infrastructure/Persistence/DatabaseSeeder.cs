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
            // First check if any company exists. If not, seed a default company and shop
            var company = await context.Companies.Include(c => c.Shop).FirstOrDefaultAsync(cancellationToken);
            if (company == null)
            {
                company = new Company
                {
                    CompanyName = "LitePOS Cafe & Desserts",
                    LegalName = "LitePOS Hospitality Pvt Ltd",
                    BusinessType = BusinessType.Cafe,
                    GSTIN = "33AAAAA0000A1Z5",
                    PAN = "AAAAA0000A",
                    Email = "support@litepos.com",
                    MobileNumber = "9876543210",
                    Website = "https://litepos.local",
                    LogoStorageKey = "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=200&auto=format&fit=crop&q=80",
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };

                var shop = new Shop
                {
                    Company = company,
                    ShopName = "LitePOS Main Branch",
                    AddressLine1 = "100 Commercial Street",
                    City = "Chennai",
                    State = "Tamil Nadu",
                    Pincode = "600001",
                    Country = "India",
                    ContactNumber = "9876543210",
                    Email = "branch@litepos.com",
                    TimeZone = "India Standard Time",
                    CurrencyCode = "INR",
                    InvoiceHeader = "Welcome to LitePOS Cafe",
                    InvoiceFooter = "Thank you! Please visit again.",
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };

                company.Shop = shop;
                await context.Companies.AddAsync(company, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded default Company and Shop.");
            }

            // Seed default users if none exist
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
            }

            User? admin = await context.Users.FirstOrDefaultAsync(u => u.Username == "admin", cancellationToken);
            if (admin == null)
            {
                admin = new User
                {
                    CompanyId = company.Id,
                    ShopId = company.Shop?.Id,
                    FullName = "Shop Administrator",
                    Username = "admin",
                    Email = "admin@litepos.com",
                    MobileNumber = "9876543211",
                    PasswordHash = passwordHasher.HashPassword("Admin@123!"),
                    RoleId = 2, // Admin
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };
                await context.Users.AddAsync(admin, cancellationToken);
            }

            User? cashier = await context.Users.FirstOrDefaultAsync(u => u.Username == "cashier", cancellationToken);
            if (cashier == null)
            {
                cashier = new User
                {
                    CompanyId = company.Id,
                    ShopId = company.Shop?.Id,
                    FullName = "Billing Cashier",
                    Username = "cashier",
                    Email = "cashier@litepos.com",
                    MobileNumber = "9876543212",
                    PasswordHash = passwordHasher.HashPassword("Cashier@123!"),
                    RoleId = 3, // Cashier
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };
                await context.Users.AddAsync(cashier, cancellationToken);
            }

            await context.SaveChangesAsync(cancellationToken);

            // Seed Devices
            if (!await context.Devices.AnyAsync(cancellationToken))
            {
                var devices = new List<Device>
                {
                    new() { Id = "POS-MAIN-01", DeviceName = "Counter 1 Desktop POS", AppVersion = "1.0.0", IsOnline = true, SyncFailuresCount = 0, LastSyncTimeUtc = DateTime.UtcNow.AddMinutes(-5) },
                    new() { Id = "POS-COUNTER-02", DeviceName = "Counter 2 Quick Terminal", AppVersion = "1.0.0", IsOnline = true, SyncFailuresCount = 0, LastSyncTimeUtc = DateTime.UtcNow.AddMinutes(-12) },
                    new() { Id = "POS-TABLET-03", DeviceName = "Floor Service Tablet", AppVersion = "1.0.0", IsOnline = false, SyncFailuresCount = 2, LastSyncTimeUtc = DateTime.UtcNow.AddHours(-3) }
                };
                await context.Devices.AddRangeAsync(devices, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded POS Devices.");
            }

            // Seed Customers
            if (!await context.Customers.AnyAsync(cancellationToken))
            {
                var customers = new List<Customer>
                {
                    new() { CustomerName = "Karthik Raja", MobileNumber = "9876543201", Email = "karthik@example.com", EmailConsent = true, WhatsAppConsent = true, IsActive = true, CreatedAtUtc = DateTime.UtcNow.AddDays(-10) },
                    new() { CustomerName = "Priya Sundaram", MobileNumber = "9876543202", Email = "priya@example.com", EmailConsent = true, WhatsAppConsent = false, IsActive = true, CreatedAtUtc = DateTime.UtcNow.AddDays(-8) },
                    new() { CustomerName = "Anand Kumar", MobileNumber = "9876543203", Email = "anand@example.com", EmailConsent = false, WhatsAppConsent = true, IsActive = true, CreatedAtUtc = DateTime.UtcNow.AddDays(-5) }
                };
                await context.Customers.AddRangeAsync(customers, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded Customers.");
            }

            // Seed Sample Invoices and Payments for Dashboard if none exist
            if (!await context.Invoices.AnyAsync(cancellationToken))
            {
                var now = DateTime.UtcNow;
                var today = now.Date;
                var cust1 = await context.Customers.FirstOrDefaultAsync(cancellationToken);
                var shopId = company.Shop?.Id ?? 1;

                // Today Invoices
                var sampleInvoices = new List<(string InvNo, decimal Sub, decimal Tax, decimal Total, PaymentMode Mode, string ModeName, DateTime Time, InvoiceStatus Status, User CashierUser)>
                {
                    ("INV-2026-0001", 428.57m, 21.43m, 450.00m, PaymentMode.Cash, "Cash", today.AddHours(10).AddMinutes(15), InvoiceStatus.Active, cashier),
                    ("INV-2026-0002", 742.86m, 37.14m, 780.00m, PaymentMode.UPI, "UPI", today.AddHours(12).AddMinutes(30), InvoiceStatus.Active, cashier),
                    ("INV-2026-0003", 304.76m, 15.24m, 320.00m, PaymentMode.Card, "Card", today.AddHours(14).AddMinutes(10), InvoiceStatus.Active, admin),
                    ("INV-2026-0004", 1190.48m, 59.52m, 1250.00m, PaymentMode.UPI, "UPI", today.AddHours(16).AddMinutes(45), InvoiceStatus.Active, cashier),
                    ("INV-2026-0005", 523.81m, 26.19m, 550.00m, PaymentMode.Cash, "Cash", today.AddHours(18).AddMinutes(20), InvoiceStatus.Active, cashier),
                    ("INV-2026-0006", 276.19m, 13.81m, 290.00m, PaymentMode.Cash, "Cash", today.AddHours(19).AddMinutes(0), InvoiceStatus.Held, cashier)
                };

                foreach (var sample in sampleInvoices)
                {
                    var isPaid = sample.Status == InvoiceStatus.Active;
                    var inv = new Invoice
                    {
                        InvoiceNumber = sample.InvNo,
                        CompanyId = company.Id,
                        ShopId = shopId,
                        CustomerId = cust1?.Id,
                        CashierId = sample.CashierUser.Id,
                        DeviceId = "POS-MAIN-01",
                        InvoiceDateUtc = sample.Time,
                        SubTotal = sample.Sub,
                        TaxableAmount = sample.Sub,
                        TaxAmount = sample.Tax,
                        GrandTotal = sample.Total,
                        PaidAmount = isPaid ? sample.Total : 0m,
                        BalanceAmount = isPaid ? 0m : sample.Total,
                        PaymentStatus = isPaid ? PaymentStatus.Paid : PaymentStatus.Pending,
                        InvoiceStatus = sample.Status,
                        SyncStatus = SyncStatus.Synced,
                        CreatedAtUtc = sample.Time
                    };

                    if (isPaid)
                    {
                        var pay = new Payment
                        {
                            Invoice = inv,
                            PaymentMode = sample.Mode,
                            PaymentModeName = sample.ModeName,
                            Amount = sample.Total,
                            TransactionReference = sample.Mode == PaymentMode.UPI ? "UPI-" + Guid.NewGuid().ToString("N")[..8].ToUpper() : null,
                            PaymentStatus = PaymentStatus.Paid,
                            CreatedAtUtc = sample.Time
                        };
                        inv.Payments.Add(pay);
                    }

                    await context.Invoices.AddAsync(inv, cancellationToken);
                }

                // Add sample historical invoices for 7-day trend
                for (int daysAgo = 1; daysAgo <= 6; daysAgo++)
                {
                    var pastDate = today.AddDays(-daysAgo).AddHours(13);
                    var dayTotal = 3000m + (daysAgo * 500m);
                    var dayTax = Math.Round(dayTotal * 0.05m, 2);
                    var daySub = dayTotal - dayTax;

                    var histInv = new Invoice
                    {
                        InvoiceNumber = $"INV-2026-0{10 + daysAgo}",
                        CompanyId = company.Id,
                        ShopId = shopId,
                        CustomerId = cust1?.Id,
                        CashierId = cashier.Id,
                        DeviceId = "POS-MAIN-01",
                        InvoiceDateUtc = pastDate,
                        SubTotal = daySub,
                        TaxableAmount = daySub,
                        TaxAmount = dayTax,
                        GrandTotal = dayTotal,
                        PaidAmount = dayTotal,
                        BalanceAmount = 0m,
                        PaymentStatus = PaymentStatus.Paid,
                        InvoiceStatus = InvoiceStatus.Active,
                        SyncStatus = SyncStatus.Synced,
                        CreatedAtUtc = pastDate
                    };

                    var histPay = new Payment
                    {
                        Invoice = histInv,
                        PaymentMode = daysAgo % 2 == 0 ? PaymentMode.UPI : PaymentMode.Cash,
                        PaymentModeName = daysAgo % 2 == 0 ? "UPI" : "Cash",
                        Amount = dayTotal,
                        PaymentStatus = PaymentStatus.Paid,
                        CreatedAtUtc = pastDate
                    };
                    histInv.Payments.Add(histPay);
                    await context.Invoices.AddAsync(histInv, cancellationToken);
                }

                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded Sample Invoices and Payments for Dashboard.");
            }

            // Seed Categories and Products (Module 4 & 5)
            if (!await context.Categories.AnyAsync(cancellationToken))
            {
                var coffeeCat = new Category { CategoryName = "Coffee", Description = "Freshly brewed hot and cold coffee", DisplayOrder = 1, IsActive = true, CreatedAtUtc = DateTime.UtcNow };
                var bevCat = new Category { CategoryName = "Beverages", Description = "Refreshing teas, coolers, and milkshakes", DisplayOrder = 2, IsActive = true, CreatedAtUtc = DateTime.UtcNow };
                var snackCat = new Category { CategoryName = "Snacks", Description = "Sandwiches, quick bites, and fast food", DisplayOrder = 3, IsActive = true, CreatedAtUtc = DateTime.UtcNow };
                var iceCat = new Category { CategoryName = "Ice Cream", Description = "Artisanal scoops and tubs", DisplayOrder = 4, IsActive = true, CreatedAtUtc = DateTime.UtcNow };
                var dessertCat = new Category { CategoryName = "Desserts", Description = "Cakes, pastries, and brownies", DisplayOrder = 5, IsActive = true, CreatedAtUtc = DateTime.UtcNow };

                var categories = new List<Category> { coffeeCat, bevCat, snackCat, iceCat, dessertCat };
                await context.Categories.AddRangeAsync(categories, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);

                var products = new List<Product>
                {
                    new()
                    {
                        CompanyId = company.Id,
                        Category = coffeeCat,
                        ProductName = "Cappuccino",
                        Description = "Espresso with steamed milk foam and cocoa powder",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 120.00m,
                        TaxPercentage = 5.0m,
                        HSNCode = "0901",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    },
                    new()
                    {
                        CompanyId = company.Id,
                        Category = bevCat,
                        ProductName = "Tea",
                        Description = "Traditional hot spiced milk tea",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 30.00m,
                        TaxPercentage = 5.0m,
                        HSNCode = "0902",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    },
                    new()
                    {
                        CompanyId = company.Id,
                        Category = snackCat,
                        ProductName = "Sandwich",
                        Description = "Grilled vegetable sandwich with mint chutney",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 100.00m,
                        TaxPercentage = 5.0m,
                        HSNCode = "1905",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    },
                    new()
                    {
                        CompanyId = company.Id,
                        Category = bevCat,
                        ProductName = "Milkshake",
                        Description = "Thick chocolate and vanilla milkshake",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 90.00m,
                        TaxPercentage = 5.0m,
                        HSNCode = "2202",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    },
                    new()
                    {
                        CompanyId = company.Id,
                        Category = iceCat,
                        ProductName = "Vanilla Ice Cream",
                        Description = "Classic creamy vanilla scoop",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 70.00m,
                        TaxPercentage = 18.0m,
                        HSNCode = "2105",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    },
                    new()
                    {
                        CompanyId = company.Id,
                        Category = dessertCat,
                        ProductName = "Chocolate Brownie",
                        Description = "Rich fudge brownie with chocolate chips",
                        ProductImageStorageKey = "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&auto=format&fit=crop&q=80",
                        SellingPrice = 110.00m,
                        TaxPercentage = 18.0m,
                        HSNCode = "1905",
                        IsAvailable = true,
                        IsActive = true,
                        CreatedAtUtc = DateTime.UtcNow
                    }
                };

                await context.Products.AddRangeAsync(products, cancellationToken);
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Seeded 5 default Categories and 6 specification Products.");
            }

            // Backfill Company Logo if missing
            if (string.IsNullOrEmpty(company.LogoStorageKey))
            {
                company.LogoStorageKey = "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=200&auto=format&fit=crop&q=80";
                context.Companies.Update(company);
                await context.SaveChangesAsync(cancellationToken);
            }

            // Backfill Product Images if missing
            var existingProducts = await context.Products.ToListAsync(cancellationToken);
            var imageMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "Cappuccino", "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&auto=format&fit=crop&q=80" },
                { "Tea", "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&auto=format&fit=crop&q=80" },
                { "Sandwich", "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&auto=format&fit=crop&q=80" },
                { "Milkshake", "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&auto=format&fit=crop&q=80" },
                { "Vanilla Ice Cream", "https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=400&auto=format&fit=crop&q=80" },
                { "Chocolate Brownie", "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&auto=format&fit=crop&q=80" }
            };

            bool updatedAny = false;
            foreach (var p in existingProducts)
            {
                if (string.IsNullOrEmpty(p.ProductImageStorageKey) && imageMap.TryGetValue(p.ProductName, out var imgUrl))
                {
                    p.ProductImageStorageKey = imgUrl;
                    context.Products.Update(p);
                    updatedAny = true;
                }
            }
            if (updatedAny)
            {
                await context.SaveChangesAsync(cancellationToken);
                logger.LogInformation("Enriched existing products with catalog images.");
            }

            logger.LogInformation("Database seeded successfully.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error while seeding default data.");
        }
    }
}
