using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BillingPOS.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Payment> _paymentRepository;
    private readonly IRepository<Order> _orderRepository;
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<User> _userRepository;
    private readonly IRepository<Device, string> _deviceRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Shop> _shopRepository;
    private readonly IRepository<LoginAuditLog> _auditLogRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private static readonly DateTime AppStartTimeUtc = DateTime.UtcNow;

    public DashboardService(
        IRepository<Invoice> invoiceRepository,
        IRepository<Payment> paymentRepository,
        IRepository<Order> orderRepository,
        IRepository<Customer> customerRepository,
        IRepository<User> userRepository,
        IRepository<Device, string> deviceRepository,
        IRepository<Company> companyRepository,
        IRepository<Shop> shopRepository,
        IRepository<LoginAuditLog> auditLogRepository,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _customerRepository = customerRepository;
        _userRepository = userRepository;
        _deviceRepository = deviceRepository;
        _companyRepository = companyRepository;
        _shopRepository = shopRepository;
        _auditLogRepository = auditLogRepository;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
    }

    public async Task<ApiResponse<SAdminDashboardDto>> GetSAdminDashboardAsync(CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService.UtcNow;
        var startOfToday = now.Date;

        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        var shop = await _shopRepository.FirstOrDefaultAsync(s => s.IsActive, cancellationToken);

        var shopInfo = new ShopInfoDto(
            CompanyName: company?.CompanyName ?? "LitePOS Enterprise",
            ShopName: shop?.ShopName ?? "Main Cafe & Desserts Branch",
            BusinessType: company?.BusinessType.ToString() ?? "Cafe",
            GSTIN: company?.GSTIN ?? shop?.ContactNumber,
            ContactNumber: shop?.ContactNumber ?? company?.MobileNumber ?? "9876543210",
            City: shop?.City ?? "Chennai",
            State: shop?.State ?? "Tamil Nadu"
        );

        var totalUsers = await _userRepository.CountAsync(null, cancellationToken);
        var activeUsers = await _userRepository.CountAsync(u => u.IsActive, cancellationToken);

        var totalDevices = await _deviceRepository.CountAsync(null, cancellationToken);
        var offlineDevices = await _deviceRepository.CountAsync(d => !d.IsOnline, cancellationToken);
        var syncFailures = await _deviceRepository.Query().SumAsync(d => (int?)d.SyncFailuresCount, cancellationToken) ?? 0;

        var validInvoicesQuery = _invoiceRepository.Query().Where(i => i.InvoiceStatus != InvoiceStatus.Cancelled);
        var totalInvoices = await validInvoicesQuery.CountAsync(cancellationToken);
        var totalSales = await validInvoicesQuery.SumAsync(i => (decimal?)i.GrandTotal, cancellationToken) ?? 0m;

        var todayInvoicesQuery = validInvoicesQuery.Where(i => i.InvoiceDateUtc >= startOfToday);
        var todayInvoices = await todayInvoicesQuery.CountAsync(cancellationToken);
        var todaySales = await todayInvoicesQuery.SumAsync(i => (decimal?)i.GrandTotal, cancellationToken) ?? 0m;

        var uptime = (now - AppStartTimeUtc);
        var uptimeString = $"{(int)uptime.TotalHours}h {uptime.Minutes}m";
        var appHealth = new AppHealthDto("Healthy", "SQL Server (Connected)", uptimeString, now);

        var recentAuditLogs = await _auditLogRepository.Query()
            .OrderByDescending(a => a.AttemptedAtUtc)
            .Take(6)
            .Select(a => new LoginAuditLogDto(
                a.Id,
                a.UserId,
                a.UsernameAttempted,
                a.IsSuccess,
                a.IpAddress,
                a.DeviceId,
                a.FailureReason,
                a.AttemptedAtUtc
            ))
            .ToListAsync(cancellationToken);

        var dto = new SAdminDashboardDto(
            shopInfo,
            totalUsers,
            activeUsers,
            totalDevices,
            offlineDevices,
            syncFailures,
            totalInvoices,
            totalSales,
            todaySales,
            todayInvoices,
            appHealth,
            recentAuditLogs
        );

        return ApiResponse<SAdminDashboardDto>.Ok(dto);
    }

    public async Task<ApiResponse<AdminDashboardDto>> GetAdminDashboardAsync(
        DateTime? date = null, 
        CancellationToken cancellationToken = default)
    {
        var targetDate = (date ?? _dateTimeService.UtcNow).Date;
        var nextDay = targetDate.AddDays(1);

        var todayInvoicesQuery = _invoiceRepository.Query()
            .Where(i => i.InvoiceDateUtc >= targetDate && i.InvoiceDateUtc < nextDay && i.InvoiceStatus != InvoiceStatus.Cancelled);

        var todayInvoices = await todayInvoicesQuery.CountAsync(cancellationToken);
        var todaySales = await todayInvoicesQuery.SumAsync(i => (decimal?)i.GrandTotal, cancellationToken) ?? 0m;

        // Payment aggregations today
        var todayPaymentsQuery = _paymentRepository.Query()
            .Where(p => p.CreatedAtUtc >= targetDate && p.CreatedAtUtc < nextDay && p.PaymentStatus == PaymentStatus.Paid);

        var cashSales = await todayPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.Cash)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var upiSales = await todayPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.UPI)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var cardSales = await todayPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.Card)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var totalCustomers = await _customerRepository.CountAsync(c => c.IsActive, cancellationToken);

        var completedOrders = await _orderRepository.CountAsync(
            o => o.CreatedAtUtc >= targetDate && o.CreatedAtUtc < nextDay && o.OrderStatus == OrderStatus.Completed, 
            cancellationToken);

        var cancelledOrders = await _orderRepository.CountAsync(
            o => o.CreatedAtUtc >= targetDate && o.CreatedAtUtc < nextDay && o.OrderStatus == OrderStatus.Cancelled, 
            cancellationToken);

        // Daily Hourly trend for today (e.g., 09:00 to 22:00 in 2-hour slots)
        var todayAllInvoices = await todayInvoicesQuery
            .Select(i => new { i.InvoiceDateUtc, i.GrandTotal })
            .ToListAsync(cancellationToken);

        var dailySalesGraph = new List<SalesGraphPointDto>();
        for (int hour = 9; hour <= 21; hour += 2)
        {
            var endSlot = hour + 2;
            var slotLabel = $"{hour:D2}:00 - {endSlot:D2}:00";
            var inSlot = todayAllInvoices.Where(i => i.InvoiceDateUtc.Hour >= hour && i.InvoiceDateUtc.Hour < endSlot).ToList();
            dailySalesGraph.Add(new SalesGraphPointDto(
                slotLabel,
                inSlot.Sum(x => x.GrandTotal),
                inSlot.Count
            ));
        }

        // Monthly / Last 7 Days trend
        var sevenDaysAgo = targetDate.AddDays(-6);
        var pastWeekInvoices = await _invoiceRepository.Query()
            .Where(i => i.InvoiceDateUtc >= sevenDaysAgo && i.InvoiceDateUtc < nextDay && i.InvoiceStatus != InvoiceStatus.Cancelled)
            .Select(i => new { i.InvoiceDateUtc.Date, i.GrandTotal })
            .ToListAsync(cancellationToken);

        var monthlySalesGraph = new List<SalesGraphPointDto>();
        for (int i = 6; i >= 0; i--)
        {
            var curDay = targetDate.AddDays(-i);
            var label = curDay.ToString("dd MMM");
            var dayInvoices = pastWeekInvoices.Where(x => x.Date == curDay).ToList();
            monthlySalesGraph.Add(new SalesGraphPointDto(
                label,
                dayInvoices.Sum(x => x.GrandTotal),
                dayInvoices.Count
            ));
        }

        // Cashier-wise breakdown today
        var cashierSales = await _invoiceRepository.Query()
            .Include(i => i.Cashier)
            .Where(i => i.InvoiceDateUtc >= targetDate && i.InvoiceDateUtc < nextDay && i.InvoiceStatus != InvoiceStatus.Cancelled)
            .GroupBy(i => new { i.CashierId, i.Cashier.FullName })
            .Select(g => new CashierSalesDto(
                g.Key.CashierId,
                g.Key.FullName,
                g.Count(),
                g.Sum(x => x.GrandTotal)
            ))
            .ToListAsync(cancellationToken);

        // Recent Invoices today (last 10)
        var recentInvoices = await _invoiceRepository.Query()
            .Include(i => i.Customer)
            .Include(i => i.Cashier)
            .Include(i => i.Payments)
            .OrderByDescending(i => i.InvoiceDateUtc)
            .Take(10)
            .Select(i => new RecentTransactionDto(
                i.Id,
                i.InvoiceNumber,
                i.Customer != null ? i.Customer.CustomerName : "Walk-in Guest",
                i.Cashier.FullName,
                i.GrandTotal,
                i.Payments.Any() ? i.Payments.First().PaymentModeName : "Cash",
                i.PaymentStatus.ToString(),
                i.InvoiceStatus.ToString(),
                i.InvoiceDateUtc
            ))
            .ToListAsync(cancellationToken);

        var dto = new AdminDashboardDto(
            todaySales,
            todayInvoices,
            cashSales,
            upiSales,
            cardSales,
            totalCustomers,
            completedOrders,
            cancelledOrders,
            dailySalesGraph,
            monthlySalesGraph,
            cashierSales,
            recentInvoices
        );

        return ApiResponse<AdminDashboardDto>.Ok(dto);
    }

    public async Task<ApiResponse<CashierDashboardDto>> GetCashierDashboardAsync(
        long? cashierId = null, 
        DateTime? date = null, 
        CancellationToken cancellationToken = default)
    {
        var targetCashierId = cashierId ?? _currentUserService.UserId ?? 0;
        var cashierUser = await _userRepository.GetByIdAsync(targetCashierId, cancellationToken);
        var cashierName = cashierUser?.FullName ?? "Cashier Operator";

        var targetDate = (date ?? _dateTimeService.UtcNow).Date;
        var nextDay = targetDate.AddDays(1);

        var cashierInvoicesQuery = _invoiceRepository.Query()
            .Where(i => i.CashierId == targetCashierId && i.InvoiceDateUtc >= targetDate && i.InvoiceDateUtc < nextDay && i.InvoiceStatus != InvoiceStatus.Cancelled);

        var todayInvoices = await cashierInvoicesQuery.CountAsync(cancellationToken);
        var todaySales = await cashierInvoicesQuery.SumAsync(i => (decimal?)i.GrandTotal, cancellationToken) ?? 0m;

        // Cashier payments
        var cashierPaymentsQuery = _paymentRepository.Query()
            .Include(p => p.Invoice)
            .Where(p => p.Invoice.CashierId == targetCashierId && p.CreatedAtUtc >= targetDate && p.CreatedAtUtc < nextDay && p.PaymentStatus == PaymentStatus.Paid);

        var cashCollected = await cashierPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.Cash)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var upiCollected = await cashierPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.UPI)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var cardCollected = await cashierPaymentsQuery
            .Where(p => p.PaymentMode == PaymentMode.Card)
            .SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var heldBillsCount = await _invoiceRepository.CountAsync(
            i => i.CashierId == targetCashierId && i.InvoiceStatus == InvoiceStatus.Held, 
            cancellationToken);

        var recentTransactions = await _invoiceRepository.Query()
            .Include(i => i.Customer)
            .Include(i => i.Payments)
            .Where(i => i.CashierId == targetCashierId)
            .OrderByDescending(i => i.InvoiceDateUtc)
            .Take(10)
            .Select(i => new RecentTransactionDto(
                i.Id,
                i.InvoiceNumber,
                i.Customer != null ? i.Customer.CustomerName : "Walk-in Guest",
                cashierName,
                i.GrandTotal,
                i.Payments.Any() ? i.Payments.First().PaymentModeName : "Cash",
                i.PaymentStatus.ToString(),
                i.InvoiceStatus.ToString(),
                i.InvoiceDateUtc
            ))
            .ToListAsync(cancellationToken);

        const decimal openingFloat = 1000.00m;
        var totalCollected = cashCollected + upiCollected + cardCollected;
        var cashOnHand = openingFloat + cashCollected;

        var shiftSummary = new ShiftSummaryDto(
            targetDate.AddHours(9),
            openingFloat,
            totalCollected,
            cashOnHand,
            upiCollected,
            cardCollected
        );

        var dto = new CashierDashboardDto(
            targetCashierId,
            cashierName,
            todaySales,
            todayInvoices,
            cashCollected,
            upiCollected,
            cardCollected,
            heldBillsCount,
            recentTransactions,
            shiftSummary
        );

        return ApiResponse<CashierDashboardDto>.Ok(dto);
    }

    public async Task<ApiResponse<SalesSummaryDto>> GetSalesSummaryAsync(
        string period = "today", 
        CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService.UtcNow;
        DateTime startDate = period.ToLower() switch
        {
            "this_week" => now.Date.AddDays(-(int)now.DayOfWeek),
            "this_month" => new DateTime(now.Year, now.Month, 1),
            "this_year" => new DateTime(now.Year, 1, 1),
            _ => now.Date // default today
        };

        var query = _invoiceRepository.Query()
            .Where(i => i.InvoiceDateUtc >= startDate && i.InvoiceStatus != InvoiceStatus.Cancelled);

        var totalInvoices = await query.CountAsync(cancellationToken);
        var totalSales = await query.SumAsync(i => (decimal?)i.GrandTotal, cancellationToken) ?? 0m;
        var totalTax = await query.SumAsync(i => (decimal?)i.TaxAmount, cancellationToken) ?? 0m;
        var totalDiscount = await query.SumAsync(i => (decimal?)i.DiscountAmount, cancellationToken) ?? 0m;
        var avgBillValue = totalInvoices > 0 ? Math.Round(totalSales / totalInvoices, 2) : 0m;

        var dto = new SalesSummaryDto(
            period,
            totalSales,
            totalInvoices,
            avgBillValue,
            totalTax,
            totalDiscount
        );

        return ApiResponse<SalesSummaryDto>.Ok(dto);
    }

    public async Task<ApiResponse<PaymentSummaryDto>> GetPaymentSummaryAsync(
        string period = "today", 
        CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService.UtcNow;
        DateTime startDate = period.ToLower() switch
        {
            "this_month" => new DateTime(now.Year, now.Month, 1),
            _ => now.Date
        };

        var query = _paymentRepository.Query()
            .Where(p => p.CreatedAtUtc >= startDate && p.PaymentStatus == PaymentStatus.Paid);

        var cash = await query.Where(p => p.PaymentMode == PaymentMode.Cash).SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;
        var upi = await query.Where(p => p.PaymentMode == PaymentMode.UPI).SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;
        var card = await query.Where(p => p.PaymentMode == PaymentMode.Card).SumAsync(p => (decimal?)p.Amount, cancellationToken) ?? 0m;

        var total = cash + upi + card;
        double cashPct = total > 0 ? (double)Math.Round(cash / total * 100m, 1) : 0.0;
        double upiPct = total > 0 ? (double)Math.Round(upi / total * 100m, 1) : 0.0;
        double cardPct = total > 0 ? (double)Math.Round(card / total * 100m, 1) : 0.0;

        var dto = new PaymentSummaryDto(
            period,
            total,
            cash,
            upi,
            card,
            cashPct,
            upiPct,
            cardPct
        );

        return ApiResponse<PaymentSummaryDto>.Ok(dto);
    }

    public async Task<ApiResponse<List<RecentTransactionDto>>> GetRecentTransactionsAsync(
        int limit = 10, 
        long? cashierId = null, 
        CancellationToken cancellationToken = default)
    {
        var query = _invoiceRepository.Query()
            .Include(i => i.Customer)
            .Include(i => i.Cashier)
            .Include(i => i.Payments)
            .AsNoTracking();

        if (cashierId.HasValue && cashierId.Value > 0)
        {
            query = query.Where(i => i.CashierId == cashierId.Value);
        }

        var list = await query
            .OrderByDescending(i => i.InvoiceDateUtc)
            .Take(limit)
            .Select(i => new RecentTransactionDto(
                i.Id,
                i.InvoiceNumber,
                i.Customer != null ? i.Customer.CustomerName : "Walk-in Guest",
                i.Cashier.FullName,
                i.GrandTotal,
                i.Payments.Any() ? i.Payments.First().PaymentModeName : "Cash",
                i.PaymentStatus.ToString(),
                i.InvoiceStatus.ToString(),
                i.InvoiceDateUtc
            ))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<RecentTransactionDto>>.Ok(list);
    }
}

