using System.Diagnostics;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class SyncService : ISyncService
{
    private readonly IRepository<Device, string> _deviceRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Category> _categoryRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Tax> _taxRepository;
    private readonly IRepository<HsnSac> _hsnSacRepository;
    private readonly IRepository<GstConfiguration> _gstConfigRepository;
    private readonly IRepository<SyncAuditLog> _syncAuditLogRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private readonly ILogger<SyncService> _logger;

    public SyncService(
        IRepository<Device, string> deviceRepository,
        IRepository<Invoice> invoiceRepository,
        IRepository<Customer> customerRepository,
        IRepository<Company> companyRepository,
        IRepository<Category> categoryRepository,
        IRepository<Product> productRepository,
        IRepository<Tax> taxRepository,
        IRepository<HsnSac> hsnSacRepository,
        IRepository<GstConfiguration> gstConfigRepository,
        IRepository<SyncAuditLog> syncAuditLogRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService,
        ILogger<SyncService> logger)
    {
        _deviceRepository = deviceRepository;
        _invoiceRepository = invoiceRepository;
        _customerRepository = customerRepository;
        _companyRepository = companyRepository;
        _categoryRepository = categoryRepository;
        _productRepository = productRepository;
        _taxRepository = taxRepository;
        _hsnSacRepository = hsnSacRepository;
        _gstConfigRepository = gstConfigRepository;
        _syncAuditLogRepository = syncAuditLogRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
        _logger = logger;
    }

    public async Task<DeviceStatusDto> RegisterDeviceAsync(RegisterDeviceDto dto, CancellationToken cancellationToken = default)
    {
        var now = _dateTimeService.UtcNow;
        var device = await _deviceRepository.GetByIdAsync(dto.DeviceId, cancellationToken);

        if (device != null)
        {
            device.DeviceName = dto.DeviceName;
            device.AppVersion = dto.AppVersion;
            device.IsOnline = dto.IsOnline;
            _deviceRepository.Update(device);
        }
        else
        {
            device = new Device
            {
                Id = dto.DeviceId,
                DeviceName = dto.DeviceName,
                AppVersion = dto.AppVersion,
                IsOnline = dto.IsOnline,
                RegisteredAtUtc = now,
                SyncFailuresCount = 0
            };
            await _deviceRepository.AddAsync(device, cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Device {DeviceId} ({DeviceName}) registered/updated successfully.", dto.DeviceId, dto.DeviceName);

        return new DeviceStatusDto(
            device.Id,
            device.DeviceName,
            device.AppVersion,
            device.IsOnline,
            device.LastSyncTimeUtc,
            device.SyncFailuresCount,
            device.RegisteredAtUtc);
    }

    public async Task<DeviceStatusDto?> GetDeviceStatusAsync(string deviceId, CancellationToken cancellationToken = default)
    {
        var device = await _deviceRepository.GetByIdAsync(deviceId, cancellationToken);
        if (device == null)
            return null;

        return new DeviceStatusDto(
            device.Id,
            device.DeviceName,
            device.AppVersion,
            device.IsOnline,
            device.LastSyncTimeUtc,
            device.SyncFailuresCount,
            device.RegisteredAtUtc);
    }

    public async Task<SyncPushResultDto> PushSyncBatchAsync(SyncPushRequestDto request, CancellationToken cancellationToken = default)
    {
        var sw = Stopwatch.StartNew();
        var startTime = _dateTimeService.UtcNow;
        var errors = new List<string>();
        var syncedCustomers = new List<SyncedEntityMappingDto>();
        var syncedInvoices = new List<SyncedEntityMappingDto>();

        // 1. Process Offline Customers
        var customerGuidMap = new Dictionary<Guid, long>();
        if (request.Customers != null)
        {
            foreach (var custDto in request.Customers)
            {
                try
                {
                    // Check duplicate GUID
                    var existingGuid = await _customerRepository.Query()
                        .FirstOrDefaultAsync(c => c.CustomerGuid == custDto.CustomerGuid, cancellationToken);

                    if (existingGuid != null)
                    {
                        customerGuidMap[custDto.CustomerGuid] = existingGuid.Id;
                        syncedCustomers.Add(new SyncedEntityMappingDto(custDto.CustomerGuid, existingGuid.Id, existingGuid.CustomerName, true));
                        continue;
                    }

                    // Check duplicate Mobile
                    var existingMobile = await _customerRepository.Query()
                        .FirstOrDefaultAsync(c => c.MobileNumber == custDto.MobileNumber, cancellationToken);

                    if (existingMobile != null)
                    {
                        customerGuidMap[custDto.CustomerGuid] = existingMobile.Id;
                        syncedCustomers.Add(new SyncedEntityMappingDto(custDto.CustomerGuid, existingMobile.Id, existingMobile.CustomerName, true));
                        continue;
                    }

                    var newCustomer = new Customer
                    {
                        CustomerGuid = custDto.CustomerGuid,
                        CustomerName = custDto.CustomerName,
                        MobileNumber = custDto.MobileNumber,
                        WhatsAppNumber = custDto.WhatsAppNumber ?? custDto.MobileNumber,
                        Email = custDto.Email,
                        Address = custDto.Address,
                        GSTIN = custDto.GSTIN,
                        EmailConsent = custDto.EmailConsent,
                        WhatsAppConsent = custDto.WhatsAppConsent,
                        IsActive = true,
                        CreatedAtUtc = custDto.CreatedAtUtc ?? startTime
                    };

                    await _customerRepository.AddAsync(newCustomer, cancellationToken);
                    await _unitOfWork.SaveChangesAsync(cancellationToken);

                    customerGuidMap[custDto.CustomerGuid] = newCustomer.Id;
                    syncedCustomers.Add(new SyncedEntityMappingDto(custDto.CustomerGuid, newCustomer.Id, newCustomer.CustomerName, false));
                }
                catch (Exception ex)
                {
                    errors.Add($"Failed to sync customer {custDto.CustomerName} ({custDto.CustomerGuid}): {ex.Message}");
                }
            }
        }

        // 2. Process Offline Invoices
        if (request.Invoices != null)
        {
            foreach (var invDto in request.Invoices)
            {
                try
                {
                    // Check duplicate invoice GUID (Idempotency)
                    var existingInvoice = await _invoiceRepository.Query()
                        .FirstOrDefaultAsync(i => i.InvoiceGuid == invDto.InvoiceGuid, cancellationToken);

                    if (existingInvoice != null)
                    {
                        syncedInvoices.Add(new SyncedEntityMappingDto(invDto.InvoiceGuid, existingInvoice.Id, existingInvoice.InvoiceNumber, true));
                        continue;
                    }

                    // Resolve customer ID
                    long? resolvedCustomerId = invDto.CustomerId;
                    if (invDto.CustomerGuid.HasValue && customerGuidMap.TryGetValue(invDto.CustomerGuid.Value, out var cid))
                    {
                        resolvedCustomerId = cid;
                    }

                    var invoice = new Invoice
                    {
                        InvoiceGuid = invDto.InvoiceGuid,
                        InvoiceNumber = invDto.InvoiceNumber,
                        CompanyId = 1,
                        ShopId = 1,
                        CashierId = invDto.CashierId > 0 ? invDto.CashierId : 1,
                        CustomerId = resolvedCustomerId,
                        DeviceId = request.DeviceId,
                        InvoiceDateUtc = invDto.InvoiceDateUtc,
                        SubTotal = invDto.SubTotal,
                        DiscountAmount = invDto.DiscountAmount,
                        TaxableAmount = invDto.TaxableAmount,
                        TaxAmount = invDto.TaxAmount,
                        GrandTotal = invDto.GrandTotal,
                        PaidAmount = invDto.PaidAmount,
                        BalanceAmount = invDto.BalanceAmount,
                        PaymentStatus = invDto.PaymentStatus,
                        InvoiceStatus = invDto.InvoiceStatus,
                        SyncStatus = SyncStatus.Synced
                    };

                    if (invDto.Items != null)
                    {
                        foreach (var item in invDto.Items)
                        {
                            invoice.Items.Add(new InvoiceItem
                            {
                                ProductId = item.ProductId,
                                ProductNameSnapshot = item.ProductNameSnapshot,
                                UnitPrice = item.UnitPrice,
                                Quantity = item.Quantity,
                                DiscountAmount = item.DiscountAmount,
                                TaxPercentage = item.TaxPercentage,
                                TaxAmount = item.TaxAmount,
                                LineTotal = item.LineTotal
                            });
                        }
                    }

                    if (invDto.Payments != null)
                    {
                        foreach (var pay in invDto.Payments)
                        {
                            invoice.Payments.Add(new Payment
                            {
                                PaymentGuid = pay.PaymentGuid,
                                PaymentMode = pay.PaymentMode,
                                PaymentModeName = pay.PaymentMode.ToString(),
                                Amount = pay.Amount,
                                TransactionReference = pay.TransactionReference,
                                PaymentStatus = pay.PaymentStatus,
                                CreatedAtUtc = pay.CreatedAtUtc
                            });
                        }
                    }

                    await _invoiceRepository.AddAsync(invoice, cancellationToken);
                    await _unitOfWork.SaveChangesAsync(cancellationToken);

                    syncedInvoices.Add(new SyncedEntityMappingDto(invDto.InvoiceGuid, invoice.Id, invoice.InvoiceNumber, false));
                }
                catch (Exception ex)
                {
                    errors.Add($"Failed to sync invoice {invDto.InvoiceNumber} ({invDto.InvoiceGuid}): {ex.Message}");
                }
            }
        }

        sw.Stop();
        var endTime = _dateTimeService.UtcNow;

        // Update Device heartbeat
        var device = await _deviceRepository.GetByIdAsync(request.DeviceId, cancellationToken);
        if (device != null)
        {
            device.LastSyncTimeUtc = endTime;
            device.AppVersion = request.AppVersion;
            device.IsOnline = true;
            _deviceRepository.Update(device);
        }

        // Audit Log
        var auditLog = new SyncAuditLog
        {
            DeviceId = request.DeviceId,
            SyncType = "Push",
            Status = errors.Count == 0 ? "Success" : (syncedInvoices.Count + syncedCustomers.Count > 0 ? "Partial" : "Failed"),
            RecordsPushed = syncedCustomers.Count + syncedInvoices.Count,
            RecordsPulled = 0,
            ConflictsCount = syncedCustomers.Count(c => c.WasAlreadySynced) + syncedInvoices.Count(i => i.WasAlreadySynced),
            ErrorDetails = errors.Count > 0 ? string.Join("; ", errors) : null,
            StartedAtUtc = startTime,
            CompletedAtUtc = endTime,
            DurationMs = sw.ElapsedMilliseconds
        };

        await _syncAuditLogRepository.AddAsync(auditLog, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new SyncPushResultDto(
            TotalReceived: (request.Customers?.Count ?? 0) + (request.Invoices?.Count ?? 0),
            TotalProcessed: syncedCustomers.Count + syncedInvoices.Count,
            TotalFailed: errors.Count,
            SyncedInvoices: syncedInvoices,
            SyncedCustomers: syncedCustomers,
            Errors: errors);
    }

    public async Task<SyncPullResponseDto> PullSyncCatalogAsync(SyncPullRequestDto request, CancellationToken cancellationToken = default)
    {
        var sw = Stopwatch.StartNew();
        var startTime = _dateTimeService.UtcNow;
        var watermark = request.LastSyncTimestampUtc;

        // 1. Company
        long? companyId = _currentUserService.CompanyId;
        Company? company = null;
        if (companyId.HasValue && companyId.Value > 0)
        {
            company = await _companyRepository.Query().Include(c => c.Shop).FirstOrDefaultAsync(c => c.Id == companyId.Value, cancellationToken);
        }
        company ??= await _companyRepository.Query().Include(c => c.Shop).FirstOrDefaultAsync(cancellationToken);
        CompanyProfileDto? companyDto = null;
        if (company != null)
        {
            companyDto = new CompanyProfileDto
            {
                CompanyId = company.Id,
                CompanyName = company.CompanyName,
                LegalName = company.LegalName,
                BusinessType = company.BusinessType,
                GSTIN = company.GSTIN,
                PAN = company.PAN,
                Email = company.Email,
                MobileNumber = company.MobileNumber,
                Website = company.Website,
                LogoStorageKey = company.LogoStorageKey,
                IsActive = company.IsActive,
                CreatedAtUtc = company.CreatedAtUtc,
                UpdatedAtUtc = company.UpdatedAtUtc,
                Shop = company.Shop != null ? new ShopDto
                {
                    ShopId = company.Shop.Id,
                    CompanyId = company.Shop.CompanyId,
                    ShopName = company.Shop.ShopName,
                    AddressLine1 = company.Shop.AddressLine1,
                    AddressLine2 = company.Shop.AddressLine2,
                    City = company.Shop.City,
                    State = company.Shop.State,
                    Pincode = company.Shop.Pincode,
                    Country = company.Shop.Country,
                    ContactNumber = company.Shop.ContactNumber,
                    Email = company.Shop.Email,
                    TimeZone = company.Shop.TimeZone,
                    CurrencyCode = company.Shop.CurrencyCode,
                    InvoiceHeader = company.Shop.InvoiceHeader,
                    InvoiceFooter = company.Shop.InvoiceFooter,
                    IsActive = company.Shop.IsActive
                } : null
            };
        }

        // 2. Categories
        var categories = await _categoryRepository.Query().AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .Select(c => new CategoryDto(
                c.Id,
                c.CategoryGuid,
                c.CategoryName,
                c.Description,
                c.CategoryImageStorageKey,
                c.DisplayOrder,
                c.IsActive,
                c.Products.Count(p => p.IsActive),
                c.CreatedAtUtc,
                c.UpdatedAtUtc
            ))
            .ToListAsync(cancellationToken);

        // 3. Products
        var productsQuery = _productRepository.Query().AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.IsActive);

        if (companyId.HasValue && companyId.Value > 0)
        {
            productsQuery = productsQuery.Where(p => p.CompanyId == companyId.Value);
        }

        var products = await productsQuery
            .OrderBy(p => p.ProductName)
            .Select(p => new ProductDto(
                p.Id,
                p.ProductGuid,
                p.CompanyId,
                p.CategoryId,
                p.Category.CategoryName,
                p.ProductName,
                p.Description,
                p.ProductImageStorageKey,
                p.SellingPrice,
                p.TaxId,
                p.TaxPercentage,
                p.HSNCode,
                p.IsAvailable,
                p.IsActive,
                p.CreatedAtUtc,
                p.UpdatedAtUtc
            ))
            .ToListAsync(cancellationToken);

        // 4. Taxes
        var taxes = await _taxRepository.Query().AsNoTracking()
            .Where(t => t.IsActive)
            .Select(t => new TaxDto(
                t.Id,
                t.TaxName,
                t.RatePercentage,
                t.CgstPercentage,
                t.SgstPercentage,
                t.IgstPercentage,
                t.IsActive,
                t.IsDefault,
                t.IsTaxInclusiveDefault
            ))
            .ToListAsync(cancellationToken);

        // 5. HSN Codes
        var hsns = await _hsnSacRepository.Query().AsNoTracking()
            .Where(h => h.IsActive)
            .Select(h => new HsnSacDto(
                h.Id,
                h.Code,
                h.Description,
                h.Type,
                h.DefaultGstRate,
                h.IsActive
            ))
            .ToListAsync(cancellationToken);

        // 6. GST Configuration
        var gstConfig = await _gstConfigRepository.Query().AsNoTracking().FirstOrDefaultAsync(cancellationToken);
        GstConfigurationDto? gstConfigDto = null;
        if (gstConfig != null)
        {
            gstConfigDto = new GstConfigurationDto(
                gstConfig.Id,
                gstConfig.GSTIN,
                gstConfig.LegalName,
                gstConfig.TradeName,
                gstConfig.StateName,
                gstConfig.StateCode,
                gstConfig.IsCompositionScheme,
                gstConfig.DefaultPricingIsTaxInclusive,
                gstConfig.InvoiceTermsAndConditions,
                gstConfig.InvoiceHeader,
                gstConfig.InvoiceFooter,
                gstConfig.ShowHsnSummaryOnReceipt,
                gstConfig.ShowTaxBreakupOnReceipt
            );
        }

        // 7. Customers (Filtered by watermark if provided)
        var customerQuery = _customerRepository.Query().AsNoTracking().Where(c => c.IsActive);
        if (watermark.HasValue)
        {
            customerQuery = customerQuery.Where(c => c.CreatedAtUtc >= watermark.Value || (c.UpdatedAtUtc.HasValue && c.UpdatedAtUtc >= watermark.Value));
        }

        var customers = await customerQuery
            .Select(c => new CustomerDto(
                c.Id,
                c.CustomerGuid,
                c.CustomerName,
                c.MobileNumber,
                c.WhatsAppNumber,
                c.Email,
                c.Address,
                c.GSTIN,
                c.EmailConsent,
                c.WhatsAppConsent,
                c.Invoices.Count(i => i.InvoiceStatus == InvoiceStatus.Active),
                c.Invoices.Where(i => i.InvoiceStatus == InvoiceStatus.Active).Sum(i => (decimal?)i.GrandTotal) ?? 0m,
                c.Invoices.Where(i => i.InvoiceStatus == InvoiceStatus.Active).Max(i => (DateTime?)i.InvoiceDateUtc),
                c.IsActive,
                c.CreatedAtUtc
            ))
            .ToListAsync(cancellationToken);

        sw.Stop();
        var endTime = _dateTimeService.UtcNow;

        var totalRecords = categories.Count + products.Count + taxes.Count + hsns.Count + customers.Count + (companyDto != null ? 1 : 0) + (gstConfigDto != null ? 1 : 0);

        // Device heartbeat
        var device = await _deviceRepository.GetByIdAsync(request.DeviceId, cancellationToken);
        if (device != null)
        {
            device.LastSyncTimeUtc = endTime;
            device.IsOnline = true;
            _deviceRepository.Update(device);
        }

        // Audit Log
        var auditLog = new SyncAuditLog
        {
            DeviceId = request.DeviceId,
            SyncType = "Pull",
            Status = "Success",
            RecordsPushed = 0,
            RecordsPulled = totalRecords,
            ConflictsCount = 0,
            ErrorDetails = null,
            StartedAtUtc = startTime,
            CompletedAtUtc = endTime,
            DurationMs = sw.ElapsedMilliseconds
        };

        await _syncAuditLogRepository.AddAsync(auditLog, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new SyncPullResponseDto(
            ServerSyncTimestampUtc: endTime,
            Company: companyDto,
            Categories: categories,
            Products: products,
            Taxes: taxes,
            HsnSacs: hsns,
            GstConfiguration: gstConfigDto,
            Customers: customers,
            TotalRecords: totalRecords);
    }

    public async Task<List<SyncAuditLogDto>> GetSyncHistoryAsync(string? deviceId = null, int limit = 20, CancellationToken cancellationToken = default)
    {
        var query = _syncAuditLogRepository.Query().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(deviceId))
        {
            query = query.Where(l => l.DeviceId == deviceId);
        }

        var logs = await query
            .OrderByDescending(l => l.StartedAtUtc)
            .Take(limit)
            .Select(l => new SyncAuditLogDto(
                l.Id,
                l.DeviceId,
                l.SyncType,
                l.Status,
                l.RecordsPushed,
                l.RecordsPulled,
                l.ConflictsCount,
                l.ErrorDetails,
                l.StartedAtUtc,
                l.CompletedAtUtc,
                l.DurationMs
            ))
            .ToListAsync(cancellationToken);

        return logs;
    }
}
