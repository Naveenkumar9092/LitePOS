using System.Globalization;
using System.Text;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BillingPOS.Application.Services;

public class ReportService : IReportService
{
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<InvoiceItem> _invoiceItemRepository;
    private readonly IRepository<Payment> _paymentRepository;
    private readonly IRepository<Refund> _refundRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Category> _categoryRepository;

    public ReportService(
        IRepository<Invoice> invoiceRepository,
        IRepository<InvoiceItem> invoiceItemRepository,
        IRepository<Payment> paymentRepository,
        IRepository<Refund> refundRepository,
        IRepository<Product> productRepository,
        IRepository<Category> categoryRepository)
    {
        _invoiceRepository = invoiceRepository;
        _invoiceItemRepository = invoiceItemRepository;
        _paymentRepository = paymentRepository;
        _refundRepository = refundRepository;
        _productRepository = productRepository;
        _categoryRepository = categoryRepository;
    }

    private static (DateTime From, DateTime To) ResolveDateRange(ReportDateRangeFilterDto filter)
    {
        var now = DateTime.UtcNow;
        var from = filter.FromDateUtc ?? new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc);
        var to = filter.ToDateUtc ?? new DateTime(now.Year, now.Month, now.Day, 23, 59, 59, 999, DateTimeKind.Utc);
        return (from, to);
    }

    public async Task<SalesReportSummaryDto> GetSalesSummaryAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var query = _invoiceRepository.Query().AsNoTracking()
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to);

        if (filter.CashierId.HasValue)
        {
            query = query.Where(i => i.CashierId == filter.CashierId.Value);
        }

        var invoices = await query.ToListAsync(cancellationToken);

        var totalInvoices = invoices.Count;
        var activeInvoices = invoices.Where(i => i.InvoiceStatus == InvoiceStatus.Active).ToList();
        var totalActive = activeInvoices.Count;
        var totalCancelled = invoices.Count(i => i.InvoiceStatus == InvoiceStatus.Cancelled);

        var grossSales = activeInvoices.Sum(i => i.SubTotal);
        var totalDiscount = activeInvoices.Sum(i => i.DiscountAmount);
        var netSales = activeInvoices.Sum(i => i.TaxableAmount);
        var totalTax = activeInvoices.Sum(i => i.TaxAmount);
        var grandTotalSales = activeInvoices.Sum(i => i.GrandTotal);

        var refunds = await _refundRepository.Query().AsNoTracking()
            .Where(r => r.CreatedAtUtc >= from && r.CreatedAtUtc <= to)
            .ToListAsync(cancellationToken);

        var totalRefunds = refunds.Sum(r => r.Amount);
        var netRevenue = grandTotalSales - totalRefunds;

        var activeInvoiceIds = activeInvoices.Select(i => i.Id).ToHashSet();

        var payments = await _paymentRepository.Query().AsNoTracking()
            .Where(p => activeInvoiceIds.Contains(p.InvoiceId) && p.PaymentStatus == PaymentStatus.Paid)
            .ToListAsync(cancellationToken);

        var cashCollected = payments.Where(p => p.PaymentMode == PaymentMode.Cash).Sum(p => p.Amount);
        var upiCollected = payments.Where(p => p.PaymentMode == PaymentMode.UPI).Sum(p => p.Amount);
        var cardCollected = payments.Where(p => p.PaymentMode == PaymentMode.Card).Sum(p => p.Amount);
        var dueOutstanding = activeInvoices.Sum(i => i.BalanceAmount);

        var avgOrderValue = totalActive > 0 ? Math.Round(grandTotalSales / totalActive, 2) : 0m;

        return new SalesReportSummaryDto(
            FromDateUtc: from,
            ToDateUtc: to,
            TotalInvoices: totalInvoices,
            TotalActiveInvoices: totalActive,
            TotalCancelledInvoices: totalCancelled,
            GrossSales: Math.Round(grossSales, 2),
            TotalDiscount: Math.Round(totalDiscount, 2),
            NetSales: Math.Round(netSales, 2),
            TotalTax: Math.Round(totalTax, 2),
            GrandTotalSales: Math.Round(grandTotalSales, 2),
            TotalRefunds: Math.Round(totalRefunds, 2),
            NetRevenue: Math.Round(netRevenue, 2),
            TotalCashCollected: Math.Round(cashCollected, 2),
            TotalUpiCollected: Math.Round(upiCollected, 2),
            TotalCardCollected: Math.Round(cardCollected, 2),
            TotalDueOutstanding: Math.Round(dueOutstanding, 2),
            AverageOrderValue: avgOrderValue);
    }

    public async Task<List<DailySalesDto>> GetDailySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var invoices = await _invoiceRepository.Query().AsNoTracking()
            .Include(i => i.Payments)
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active)
            .ToListAsync(cancellationToken);

        var grouped = invoices
            .GroupBy(i => i.InvoiceDateUtc.Date)
            .OrderBy(g => g.Key)
            .Select(g =>
            {
                var payments = g.SelectMany(i => i.Payments).Where(p => p.PaymentStatus == PaymentStatus.Paid).ToList();
                return new DailySalesDto(
                    Date: g.Key,
                    InvoiceCount: g.Count(),
                    GrossSales: Math.Round(g.Sum(i => i.SubTotal), 2),
                    DiscountAmount: Math.Round(g.Sum(i => i.DiscountAmount), 2),
                    TaxAmount: Math.Round(g.Sum(i => i.TaxAmount), 2),
                    NetSales: Math.Round(g.Sum(i => i.GrandTotal), 2),
                    CashAmount: Math.Round(payments.Where(p => p.PaymentMode == PaymentMode.Cash).Sum(p => p.Amount), 2),
                    UpiAmount: Math.Round(payments.Where(p => p.PaymentMode == PaymentMode.UPI).Sum(p => p.Amount), 2),
                    CardAmount: Math.Round(payments.Where(p => p.PaymentMode == PaymentMode.Card).Sum(p => p.Amount), 2));
            })
            .ToList();

        return grouped;
    }

    public async Task<List<ProductSalesReportDto>> GetProductSalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var activeInvoiceQuery = _invoiceRepository.Query().AsNoTracking()
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active);

        if (filter.CashierId.HasValue)
        {
            activeInvoiceQuery = activeInvoiceQuery.Where(i => i.CashierId == filter.CashierId.Value);
        }

        var activeInvoiceIds = await activeInvoiceQuery.Select(i => i.Id).ToListAsync(cancellationToken);

        var items = await _invoiceItemRepository.Query().AsNoTracking()
            .Where(item => activeInvoiceIds.Contains(item.InvoiceId))
            .ToListAsync(cancellationToken);

        var productIds = items.Select(i => i.ProductId).Distinct().ToList();
        var products = await _productRepository.Query().AsNoTracking()
            .Include(p => p.Category)
            .Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id, cancellationToken);

        if (filter.CategoryId.HasValue)
        {
            items = items.Where(i => products.TryGetValue(i.ProductId, out var p) && p.CategoryId == filter.CategoryId.Value).ToList();
        }

        var totalAllRevenue = items.Sum(i => i.LineTotal);

        var productSales = items
            .GroupBy(i => i.ProductId)
            .Select(g =>
            {
                var prodId = g.Key;
                products.TryGetValue(prodId, out var prod);
                var prodName = prod?.ProductName ?? g.First().ProductNameSnapshot;
                var catName = prod?.Category?.CategoryName ?? "General";
                var qty = g.Sum(x => x.Quantity);
                var revenue = g.Sum(x => x.LineTotal);
                var tax = g.Sum(x => x.TaxAmount);
                var pct = totalAllRevenue > 0 ? Math.Round((revenue / totalAllRevenue) * 100, 2) : 0m;

                return new ProductSalesReportDto(
                    ProductId: prodId,
                    ProductName: prodName,
                    CategoryName: catName,
                    QuantitySold: qty,
                    TotalRevenue: Math.Round(revenue, 2),
                    TotalTax: Math.Round(tax, 2),
                    PercentageOfSales: pct);
            })
            .OrderByDescending(p => p.TotalRevenue)
            .ToList();

        return productSales;
    }

    public async Task<List<CategorySalesReportDto>> GetCategorySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var prodSales = await GetProductSalesReportAsync(filter, cancellationToken);
        var totalAllRevenue = prodSales.Sum(p => p.TotalRevenue);

        var categories = await _categoryRepository.Query().AsNoTracking().ToListAsync(cancellationToken);
        var categoryMap = categories.ToDictionary(c => c.CategoryName, c => c.Id);

        var categorySales = prodSales
            .GroupBy(p => p.CategoryName)
            .Select(g =>
            {
                var catName = g.Key;
                categoryMap.TryGetValue(catName, out var catId);
                var qty = g.Sum(x => x.QuantitySold);
                var revenue = g.Sum(x => x.TotalRevenue);
                var pct = totalAllRevenue > 0 ? Math.Round((revenue / totalAllRevenue) * 100, 2) : 0m;

                return new CategorySalesReportDto(
                    CategoryId: catId,
                    CategoryName: catName,
                    TotalQuantitySold: qty,
                    TotalRevenue: Math.Round(revenue, 2),
                    PercentageOfSales: pct);
            })
            .OrderByDescending(c => c.TotalRevenue)
            .ToList();

        return categorySales;
    }

    public async Task<List<CashierPerformanceReportDto>> GetCashierPerformanceReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var invoices = await _invoiceRepository.Query().AsNoTracking()
            .Include(i => i.Cashier)
            .Include(i => i.Payments)
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active)
            .ToListAsync(cancellationToken);

        var refunds = await _refundRepository.Query().AsNoTracking()
            .Where(r => r.CreatedAtUtc >= from && r.CreatedAtUtc <= to)
            .ToListAsync(cancellationToken);

        var grouped = invoices
            .GroupBy(i => i.CashierId)
            .Select(g =>
            {
                var cashier = g.First().Cashier;
                var cashierName = cashier != null ? cashier.FullName : $"Cashier #{g.Key}";
                var username = cashier?.Username ?? "Unknown";

                var payments = g.SelectMany(i => i.Payments).Where(p => p.PaymentStatus == PaymentStatus.Paid).ToList();
                var cash = payments.Where(p => p.PaymentMode == PaymentMode.Cash).Sum(p => p.Amount);
                var digital = payments.Where(p => p.PaymentMode == PaymentMode.UPI || p.PaymentMode == PaymentMode.Card).Sum(p => p.Amount);

                var cashierRefunds = refunds.Where(r => r.ProcessedBy == username || r.AuthorizedBy == username).Sum(r => r.Amount);

                return new CashierPerformanceReportDto(
                    CashierId: g.Key,
                    CashierName: cashierName,
                    Username: username,
                    InvoicesCount: g.Count(),
                    TotalSales: Math.Round(g.Sum(i => i.GrandTotal), 2),
                    CashCollected: Math.Round(cash, 2),
                    DigitalCollected: Math.Round(digital, 2),
                    RefundsHandled: Math.Round(cashierRefunds, 2));
            })
            .OrderByDescending(c => c.TotalSales)
            .ToList();

        return grouped;
    }

    public async Task<GstSummaryReportDto> GetGstSummaryReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var activeInvoices = await _invoiceRepository.Query().AsNoTracking()
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active)
            .Select(i => i.Id)
            .ToListAsync(cancellationToken);

        var items = await _invoiceItemRepository.Query().AsNoTracking()
            .Where(item => activeInvoices.Contains(item.InvoiceId))
            .ToListAsync(cancellationToken);

        var productIds = items.Select(i => i.ProductId).Distinct().ToList();
        var products = await _productRepository.Query().AsNoTracking()
            .Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id, cancellationToken);

        // Tax Slabs Grouping
        var slabs = items
            .GroupBy(i => i.TaxPercentage)
            .OrderBy(g => g.Key)
            .Select(g =>
            {
                var rate = g.Key;
                var taxable = g.Sum(x => x.LineTotal - x.TaxAmount);
                var tax = g.Sum(x => x.TaxAmount);
                var cgst = Math.Round(tax / 2, 2);
                var sgst = Math.Round(tax - cgst, 2);

                return new GstSlabSummaryDto(
                    TaxRate: rate,
                    TaxableAmount: Math.Round(taxable, 2),
                    CgstAmount: cgst,
                    SgstAmount: sgst,
                    TotalTax: Math.Round(tax, 2));
            })
            .ToList();

        var totalTaxable = slabs.Sum(s => s.TaxableAmount);
        var totalCgst = slabs.Sum(s => s.CgstAmount);
        var totalSgst = slabs.Sum(s => s.SgstAmount);
        var totalGst = slabs.Sum(s => s.TotalTax);

        // HSN Summary Grouping
        var hsnSummary = items
            .GroupBy(i =>
            {
                products.TryGetValue(i.ProductId, out var prod);
                return !string.IsNullOrWhiteSpace(prod?.HSNCode) ? prod.HSNCode : "996331"; // Cafe/Restaurant service default SAC
            })
            .OrderBy(g => g.Key)
            .Select(g =>
            {
                var hsn = g.Key;
                var qty = g.Sum(x => x.Quantity);
                var taxable = g.Sum(x => x.LineTotal - x.TaxAmount);
                var tax = g.Sum(x => x.TaxAmount);
                var total = g.Sum(x => x.LineTotal);

                return new HsnSalesSummaryDto(
                    HsnCode: hsn,
                    Description: hsn == "996331" ? "Restaurant, Cafe & Dessert Food Services" : $"HSN Code {hsn}",
                    TotalQuantity: qty,
                    TaxableAmount: Math.Round(taxable, 2),
                    TotalTax: Math.Round(tax, 2),
                    TotalValue: Math.Round(total, 2));
            })
            .ToList();

        return new GstSummaryReportDto(
            Slabs: slabs,
            TotalTaxableAmount: Math.Round(totalTaxable, 2),
            TotalCgst: Math.Round(totalCgst, 2),
            TotalSgst: Math.Round(totalSgst, 2),
            TotalGst: Math.Round(totalGst, 2),
            HsnSummary: hsnSummary);
    }

    public async Task<List<HourlySalesDto>> GetHourlySalesReportAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var invoices = await _invoiceRepository.Query().AsNoTracking()
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active)
            .ToListAsync(cancellationToken);

        var hours = Enumerable.Range(0, 24).Select(hour =>
        {
            var hourInvoices = invoices.Where(i => i.InvoiceDateUtc.Hour == hour).ToList();
            var startTime = new DateTime(2000, 1, 1, hour, 0, 0).ToString("hh:mm tt", CultureInfo.InvariantCulture);
            var nextHour = (hour + 1) % 24;
            var endTime = new DateTime(2000, 1, 1, nextHour, 0, 0).ToString("hh:mm tt", CultureInfo.InvariantCulture);

            return new HourlySalesDto(
                Hour: hour,
                TimeSlot: $"{startTime} - {endTime}",
                OrderCount: hourInvoices.Count,
                TotalSales: Math.Round(hourInvoices.Sum(i => i.GrandTotal), 2));
        }).ToList();

        return hours;
    }

    public async Task<List<PaymentModeBreakdownDto>> GetPaymentModeBreakdownAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var activeInvoices = await _invoiceRepository.Query().AsNoTracking()
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus == InvoiceStatus.Active)
            .Select(i => i.Id)
            .ToListAsync(cancellationToken);

        var payments = await _paymentRepository.Query().AsNoTracking()
            .Where(p => activeInvoices.Contains(p.InvoiceId) && p.PaymentStatus == PaymentStatus.Paid)
            .ToListAsync(cancellationToken);

        var totalAmount = payments.Sum(p => p.Amount);

        var breakdown = payments
            .GroupBy(p => p.PaymentMode)
            .Select(g =>
            {
                var modeName = g.Key.ToString();
                var count = g.Count();
                var amt = g.Sum(x => x.Amount);
                var pct = totalAmount > 0 ? Math.Round((amt / totalAmount) * 100, 2) : 0m;

                return new PaymentModeBreakdownDto(
                    PaymentMode: modeName,
                    TransactionCount: count,
                    TotalAmount: Math.Round(amt, 2),
                    Percentage: pct);
            })
            .OrderByDescending(b => b.TotalAmount)
            .ToList();

        return breakdown;
    }

    public async Task<byte[]> ExportSalesReportCsvAsync(ReportDateRangeFilterDto filter, CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(filter);

        var invoices = await _invoiceRepository.Query().AsNoTracking()
            .Include(i => i.Cashier)
            .Include(i => i.Customer)
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to)
            .OrderByDescending(i => i.InvoiceDateUtc)
            .ToListAsync(cancellationToken);

        var sb = new StringBuilder();
        sb.AppendLine("Invoice Number,Date (UTC),Status,Cashier,Customer,SubTotal,Discount,Taxable,Tax,Grand Total,Paid,Balance");

        foreach (var inv in invoices)
        {
            var cashierName = inv.Cashier?.FullName ?? "Unknown";
            var customerName = inv.Customer?.CustomerName ?? "Walk-in";

            sb.AppendLine(string.Join(",",
                EscapeCsv(inv.InvoiceNumber),
                inv.InvoiceDateUtc.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture),
                inv.InvoiceStatus.ToString(),
                EscapeCsv(cashierName),
                EscapeCsv(customerName),
                inv.SubTotal.ToString("F2", CultureInfo.InvariantCulture),
                inv.DiscountAmount.ToString("F2", CultureInfo.InvariantCulture),
                inv.TaxableAmount.ToString("F2", CultureInfo.InvariantCulture),
                inv.TaxAmount.ToString("F2", CultureInfo.InvariantCulture),
                inv.GrandTotal.ToString("F2", CultureInfo.InvariantCulture),
                inv.PaidAmount.ToString("F2", CultureInfo.InvariantCulture),
                inv.BalanceAmount.ToString("F2", CultureInfo.InvariantCulture)));
        }

        return Encoding.UTF8.GetBytes(sb.ToString());
    }

    private static string EscapeCsv(string value)
    {
        if (value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r'))
        {
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }
        return value;
    }
}
