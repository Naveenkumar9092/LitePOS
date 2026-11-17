using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class BillingService : IBillingService
{
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<InvoiceItem> _invoiceItemRepository;
    private readonly IRepository<Payment> _paymentRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Shop> _shopRepository;
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<User> _userRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IDateTimeService _dateTimeService;
    private readonly IValidator<CreateInvoiceDto> _createInvoiceValidator;
    private readonly IValidator<HoldBillDto> _holdBillValidator;
    private readonly IValidator<CancelBillDto> _cancelBillValidator;
    private readonly ILogger<BillingService> _logger;

    public BillingService(
        IRepository<Invoice> invoiceRepository,
        IRepository<InvoiceItem> invoiceItemRepository,
        IRepository<Payment> paymentRepository,
        IRepository<Product> productRepository,
        IRepository<Company> companyRepository,
        IRepository<Shop> shopRepository,
        IRepository<Customer> customerRepository,
        IRepository<User> userRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IDateTimeService dateTimeService,
        IValidator<CreateInvoiceDto> createInvoiceValidator,
        IValidator<HoldBillDto> holdBillValidator,
        IValidator<CancelBillDto> cancelBillValidator,
        ILogger<BillingService> logger)
    {
        _invoiceRepository = invoiceRepository;
        _invoiceItemRepository = invoiceItemRepository;
        _paymentRepository = paymentRepository;
        _productRepository = productRepository;
        _companyRepository = companyRepository;
        _shopRepository = shopRepository;
        _customerRepository = customerRepository;
        _userRepository = userRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _dateTimeService = dateTimeService;
        _createInvoiceValidator = createInvoiceValidator;
        _holdBillValidator = holdBillValidator;
        _cancelBillValidator = cancelBillValidator;
        _logger = logger;
    }

    public async Task<ApiResponse<InvoiceDto>> CreateInvoiceAsync(CreateInvoiceDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _createInvoiceValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<InvoiceDto>.FailureResult("Validation failed.", errors);
            }

            // Multi-Tenant Company & Shop resolution
            long targetCompanyId = _currentUserService.CompanyId ?? 1;
            var company = await _companyRepository.GetByIdAsync(targetCompanyId, cancellationToken)
                ?? await _companyRepository.Query().FirstOrDefaultAsync(cancellationToken);
            var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == targetCompanyId, cancellationToken)
                ?? await _shopRepository.Query().FirstOrDefaultAsync(cancellationToken);
            if (company == null || shop == null)
            {
                return ApiResponse<InvoiceDto>.FailureResult("Shop setup is required before creating invoices.");
            }

            long cashierId = _currentUserService.UserId ?? 1;
            var deviceId = !string.IsNullOrWhiteSpace(dto.DeviceId) ? dto.DeviceId.Trim() : "POS-TERMINAL-01";

            // Verify customer if provided
            Customer? customer = null;
            if (dto.CustomerId.HasValue && dto.CustomerId.Value > 0)
            {
                customer = await _customerRepository.GetByIdAsync(dto.CustomerId.Value, cancellationToken);
            }

            // Fetch products and validate availability
            var productIds = dto.Items.Select(i => i.ProductId).Distinct().ToList();
            var products = await _productRepository.Query()
                .Where(p => productIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, cancellationToken);

            foreach (var itemDto in dto.Items)
            {
                if (!products.TryGetValue(itemDto.ProductId, out var product))
                {
                    return ApiResponse<InvoiceDto>.FailureResult($"Product with ID {itemDto.ProductId} was not found.");
                }

                if (!product.IsAvailable || !product.IsActive)
                {
                    return ApiResponse<InvoiceDto>.FailureResult($"Product '{product.ProductName}' is currently unavailable.");
                }
            }

            // Generate invoice number
            var today = _dateTimeService.UtcNow.Date;
            var todayCount = await _invoiceRepository.Query()
                .CountAsync(i => i.CreatedAtUtc >= today, cancellationToken);
            var invoiceNumber = $"INV-{_dateTimeService.UtcNow:yyyyMMdd}-{(todayCount + 1):D4}";

            // Calculate line totals
            decimal subTotal = 0;
            decimal totalLineDiscounts = 0;
            decimal totalTax = 0;

            var invoiceItems = new List<InvoiceItem>();

            foreach (var itemDto in dto.Items)
            {
                var product = products[itemDto.ProductId];
                var unitPrice = itemDto.UnitPrice > 0 ? itemDto.UnitPrice : product.SellingPrice;
                var lineSubTotal = Math.Round(itemDto.Quantity * unitPrice, 2);
                var lineDiscount = Math.Round(itemDto.DiscountAmount, 2);
                var lineTaxable = Math.Max(0, lineSubTotal - lineDiscount);
                var taxPercentage = itemDto.TaxPercentage > 0 ? itemDto.TaxPercentage : product.TaxPercentage;
                var lineTax = Math.Round(lineTaxable * (taxPercentage / 100m), 2);
                var lineTotal = lineTaxable + lineTax;

                subTotal += lineSubTotal;
                totalLineDiscounts += lineDiscount;
                totalTax += lineTax;

                var item = new InvoiceItem
                {
                    ProductId = product.Id,
                    ProductNameSnapshot = !string.IsNullOrWhiteSpace(itemDto.ProductNameSnapshot)
                        ? itemDto.ProductNameSnapshot.Trim()
                        : product.ProductName,
                    UnitPrice = unitPrice,
                    Quantity = itemDto.Quantity,
                    DiscountAmount = lineDiscount,
                    TaxPercentage = taxPercentage,
                    TaxAmount = lineTax,
                    LineTotal = lineTotal
                };

                invoiceItems.Add(item);
            }

            var discountAmount = dto.DiscountAmount > 0 ? dto.DiscountAmount : totalLineDiscounts;
            var taxableAmount = Math.Max(0, subTotal - discountAmount);
            var grandTotal = Math.Round(taxableAmount + totalTax, 2);
            var paidAmount = Math.Round(dto.PaidAmount, 2);
            var balanceAmount = Math.Max(0, grandTotal - paidAmount);

            var paymentStatus = paidAmount >= grandTotal
                ? PaymentStatus.Paid
                : (paidAmount > 0 ? PaymentStatus.PartiallyPaid : PaymentStatus.Pending);

            var invoice = new Invoice
            {
                InvoiceGuid = Guid.NewGuid(),
                InvoiceNumber = invoiceNumber,
                CompanyId = company.Id,
                ShopId = shop.Id,
                CustomerId = customer?.Id,
                CashierId = cashierId,
                DeviceId = deviceId,
                InvoiceDateUtc = _dateTimeService.UtcNow,
                SubTotal = subTotal,
                DiscountAmount = discountAmount,
                TaxableAmount = taxableAmount,
                TaxAmount = totalTax,
                GrandTotal = grandTotal,
                PaidAmount = paidAmount,
                BalanceAmount = balanceAmount,
                PaymentStatus = paymentStatus,
                InvoiceStatus = InvoiceStatus.Active,
                SyncStatus = SyncStatus.Synced,
                CreatedAtUtc = _dateTimeService.UtcNow,
                Items = invoiceItems
            };

            await _invoiceRepository.AddAsync(invoice, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // Record payment if paid amount > 0
            Payment? payment = null;
            if (paidAmount > 0)
            {
                payment = new Payment
                {
                    PaymentGuid = Guid.NewGuid(),
                    InvoiceId = invoice.Id,
                    PaymentMode = dto.PaymentMode,
                    PaymentModeName = dto.PaymentMode.ToString(),
                    Amount = paidAmount,
                    TransactionReference = dto.TransactionReference?.Trim(),
                    PaymentStatus = PaymentStatus.Paid,
                    CreatedAtUtc = _dateTimeService.UtcNow
                };

                await _paymentRepository.AddAsync(payment, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }

            _logger.LogInformation("Invoice '{InvoiceNumber}' (ID: {InvoiceId}) created successfully. Grand Total: {GrandTotal}",
                invoice.InvoiceNumber, invoice.Id, invoice.GrandTotal);

            var resultDto = await MapToInvoiceDtoAsync(invoice.Id, cancellationToken);
            return ApiResponse<InvoiceDto>.SuccessResult(resultDto!, "Invoice generated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating invoice");
            return ApiResponse<InvoiceDto>.FailureResult("An error occurred while creating the invoice.");
        }
    }

    public async Task<ApiResponse<PagedInvoicesResultDto>> GetInvoicesAsync(
        int pageNumber = 1,
        int pageSize = 50,
        InvoiceStatus? status = null,
        string? search = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var query = _invoiceRepository.Query()
                .Include(i => i.Company)
                .Include(i => i.Shop)
                .Include(i => i.Customer)
                .Include(i => i.Cashier)
                .Include(i => i.Items)
                .Include(i => i.Payments)
                .AsQueryable();

            // Multi-Tenant Isolation
            if (_currentUserService.Role != RoleConstants.SAdmin && _currentUserService.CompanyId.HasValue)
            {
                query = query.Where(i => i.CompanyId == _currentUserService.CompanyId.Value);
            }

            if (status.HasValue)
            {
                query = query.Where(i => i.InvoiceStatus == status.Value);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                query = query.Where(i => i.InvoiceNumber.ToLower().Contains(term) ||
                                         (i.Customer != null && (i.Customer.CustomerName.ToLower().Contains(term) || i.Customer.MobileNumber.Contains(term))));
            }

            if (fromDate.HasValue)
            {
                query = query.Where(i => i.InvoiceDateUtc >= fromDate.Value);
            }

            if (toDate.HasValue)
            {
                query = query.Where(i => i.InvoiceDateUtc <= toDate.Value);
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var items = await query
                .OrderByDescending(i => i.InvoiceDateUtc)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var dtos = items.Select(MapEntityToDto).ToList();

            var pagedResult = new PagedInvoicesResultDto(dtos, totalCount, pageNumber, pageSize);
            return ApiResponse<PagedInvoicesResultDto>.SuccessResult(pagedResult);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching invoices");
            return ApiResponse<PagedInvoicesResultDto>.FailureResult("An error occurred while retrieving invoices.");
        }
    }

    public async Task<ApiResponse<InvoiceDto>> GetInvoiceByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var dto = await MapToInvoiceDtoAsync(id, cancellationToken);
            if (dto == null)
            {
                return ApiResponse<InvoiceDto>.FailureResult("Invoice not found.");
            }

            return ApiResponse<InvoiceDto>.SuccessResult(dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching invoice with ID {InvoiceId}", id);
            return ApiResponse<InvoiceDto>.FailureResult("An error occurred while retrieving the invoice.");
        }
    }

    public async Task<ApiResponse<InvoiceDto>> HoldBillAsync(HoldBillDto dto, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _holdBillValidator.ValidateAsync(dto, cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<InvoiceDto>.FailureResult("Validation failed.", errors);
            }

            var company = await _companyRepository.Query().FirstOrDefaultAsync(cancellationToken);
            var shop = await _shopRepository.Query().FirstOrDefaultAsync(cancellationToken);
            if (company == null || shop == null)
            {
                return ApiResponse<InvoiceDto>.FailureResult("Shop setup is required before holding bills.");
            }

            long cashierId = _currentUserService.UserId ?? 1;
            var deviceId = !string.IsNullOrWhiteSpace(dto.DeviceId) ? dto.DeviceId.Trim() : "POS-TERMINAL-01";

            var today = _dateTimeService.UtcNow.Date;
            var todayCount = await _invoiceRepository.Query()
                .CountAsync(i => i.CreatedAtUtc >= today, cancellationToken);
            var invoiceNumber = $"HOLD-{_dateTimeService.UtcNow:yyyyMMdd}-{(todayCount + 1):D4}";

            var productIds = dto.Items.Select(i => i.ProductId).Distinct().ToList();
            var products = await _productRepository.Query()
                .Where(p => productIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, cancellationToken);

            decimal subTotal = 0;
            decimal totalTax = 0;
            var invoiceItems = new List<InvoiceItem>();

            foreach (var itemDto in dto.Items)
            {
                products.TryGetValue(itemDto.ProductId, out var product);
                var unitPrice = itemDto.UnitPrice > 0 ? itemDto.UnitPrice : (product?.SellingPrice ?? 0);
                var productName = !string.IsNullOrWhiteSpace(itemDto.ProductNameSnapshot)
                    ? itemDto.ProductNameSnapshot.Trim()
                    : (product?.ProductName ?? "Item");
                var lineSubTotal = Math.Round(itemDto.Quantity * unitPrice, 2);
                var lineTax = Math.Round(lineSubTotal * (itemDto.TaxPercentage / 100m), 2);

                subTotal += lineSubTotal;
                totalTax += lineTax;

                invoiceItems.Add(new InvoiceItem
                {
                    ProductId = itemDto.ProductId,
                    ProductNameSnapshot = productName,
                    UnitPrice = unitPrice,
                    Quantity = itemDto.Quantity,
                    DiscountAmount = itemDto.DiscountAmount,
                    TaxPercentage = itemDto.TaxPercentage,
                    TaxAmount = lineTax,
                    LineTotal = lineSubTotal + lineTax
                });
            }

            var discountAmount = dto.DiscountAmount;
            var taxableAmount = Math.Max(0, subTotal - discountAmount);
            var grandTotal = Math.Round(taxableAmount + totalTax, 2);

            var invoice = new Invoice
            {
                InvoiceGuid = Guid.NewGuid(),
                InvoiceNumber = invoiceNumber,
                CompanyId = company.Id,
                ShopId = shop.Id,
                CustomerId = dto.CustomerId,
                CashierId = cashierId,
                DeviceId = deviceId,
                InvoiceDateUtc = _dateTimeService.UtcNow,
                SubTotal = subTotal,
                DiscountAmount = discountAmount,
                TaxableAmount = taxableAmount,
                TaxAmount = totalTax,
                GrandTotal = grandTotal,
                PaidAmount = 0,
                BalanceAmount = grandTotal,
                PaymentStatus = PaymentStatus.Pending,
                InvoiceStatus = InvoiceStatus.Held,
                SyncStatus = SyncStatus.Synced,
                CreatedAtUtc = _dateTimeService.UtcNow,
                Items = invoiceItems
            };

            await _invoiceRepository.AddAsync(invoice, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Bill held with reference '{InvoiceNumber}' (ID: {InvoiceId})", invoice.InvoiceNumber, invoice.Id);

            var resultDto = await MapToInvoiceDtoAsync(invoice.Id, cancellationToken);
            return ApiResponse<InvoiceDto>.SuccessResult(resultDto!, "Bill placed on hold successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error holding bill");
            return ApiResponse<InvoiceDto>.FailureResult("An error occurred while placing the bill on hold.");
        }
    }

    public async Task<ApiResponse<List<InvoiceDto>>> GetHeldBillsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var items = await _invoiceRepository.Query()
                .Include(i => i.Company)
                .Include(i => i.Shop)
                .Include(i => i.Customer)
                .Include(i => i.Cashier)
                .Include(i => i.Items)
                .Include(i => i.Payments)
                .Where(i => i.InvoiceStatus == InvoiceStatus.Held)
                .OrderByDescending(i => i.CreatedAtUtc)
                .ToListAsync(cancellationToken);

            var dtos = items.Select(MapEntityToDto).ToList();
            return ApiResponse<List<InvoiceDto>>.SuccessResult(dtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving held bills");
            return ApiResponse<List<InvoiceDto>>.FailureResult("An error occurred while retrieving held bills.");
        }
    }

    public async Task<ApiResponse<InvoiceDto>> ResumeBillAsync(long invoiceId, CancellationToken cancellationToken = default)
    {
        try
        {
            var invoice = await _invoiceRepository.GetByIdAsync(invoiceId, cancellationToken);
            if (invoice == null)
            {
                return ApiResponse<InvoiceDto>.FailureResult("Held bill not found.");
            }

            if (invoice.InvoiceStatus != InvoiceStatus.Held)
            {
                return ApiResponse<InvoiceDto>.FailureResult("This bill is not currently on hold.");
            }

            var dto = await MapToInvoiceDtoAsync(invoiceId, cancellationToken);
            return ApiResponse<InvoiceDto>.SuccessResult(dto!, "Held bill retrieved for resuming.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resuming held bill ID {InvoiceId}", invoiceId);
            return ApiResponse<InvoiceDto>.FailureResult("An error occurred while resuming the held bill.");
        }
    }

    public async Task<ApiResponse<bool>> CancelBillAsync(long invoiceId, string reason, CancellationToken cancellationToken = default)
    {
        try
        {
            var validation = await _cancelBillValidator.ValidateAsync(new CancelBillDto(reason), cancellationToken);
            if (!validation.IsValid)
            {
                var errors = validation.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<bool>.FailureResult("Validation failed.", errors);
            }

            var invoice = await _invoiceRepository.GetByIdAsync(invoiceId, cancellationToken);
            if (invoice == null)
            {
                return ApiResponse<bool>.FailureResult("Invoice not found.");
            }

            if (invoice.InvoiceStatus == InvoiceStatus.Cancelled)
            {
                return ApiResponse<bool>.FailureResult("Invoice is already cancelled.");
            }

            invoice.InvoiceStatus = InvoiceStatus.Cancelled;
            invoice.UpdatedAtUtc = _dateTimeService.UtcNow;

            _invoiceRepository.Update(invoice);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Invoice ID {InvoiceId} cancelled. Reason: {Reason}", invoiceId, reason);
            return ApiResponse<bool>.SuccessResult(true, "Invoice cancelled successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling invoice ID {InvoiceId}", invoiceId);
            return ApiResponse<bool>.FailureResult("An error occurred while cancelling the invoice.");
        }
    }

    public async Task<ApiResponse<InvoiceDto>> ReprintBillAsync(long invoiceId, CancellationToken cancellationToken = default)
    {
        try
        {
            var dto = await MapToInvoiceDtoAsync(invoiceId, cancellationToken);
            if (dto == null)
            {
                return ApiResponse<InvoiceDto>.FailureResult("Invoice not found.");
            }

            _logger.LogInformation("Reprint requested for Invoice ID {InvoiceId}", invoiceId);
            return ApiResponse<InvoiceDto>.SuccessResult(dto, "Invoice details retrieved for reprint.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching invoice ID {InvoiceId} for reprint", invoiceId);
            return ApiResponse<InvoiceDto>.FailureResult("An error occurred while retrieving invoice for reprint.");
        }
    }

    private async Task<InvoiceDto?> MapToInvoiceDtoAsync(long invoiceId, CancellationToken cancellationToken)
    {
        var invoice = await _invoiceRepository.Query()
            .Include(i => i.Company)
            .Include(i => i.Shop)
            .Include(i => i.Customer)
            .Include(i => i.Cashier)
            .Include(i => i.Items)
            .Include(i => i.Payments)
            .FirstOrDefaultAsync(i => i.Id == invoiceId, cancellationToken);

        if (invoice == null) return null;

        return MapEntityToDto(invoice);
    }

    private static InvoiceDto MapEntityToDto(Invoice invoice)
    {
        var items = invoice.Items.Select(item => new InvoiceItemDto(
            item.Id,
            item.InvoiceId,
            item.ProductId,
            item.ProductNameSnapshot,
            item.UnitPrice,
            item.Quantity,
            item.DiscountAmount,
            item.TaxPercentage,
            item.TaxAmount,
            item.LineTotal
        )).ToList();

        var payments = invoice.Payments.Select(p => new PaymentDto(
            p.Id,
            p.PaymentGuid,
            p.InvoiceId,
            p.PaymentMode,
            p.PaymentModeName,
            p.Amount,
            p.TransactionReference,
            p.PaymentStatus,
            p.CreatedAtUtc
        )).ToList();

        return new InvoiceDto(
            invoice.Id,
            invoice.InvoiceGuid,
            invoice.InvoiceNumber,
            invoice.CompanyId,
            invoice.Company?.CompanyName ?? "LitePOS Company",
            invoice.ShopId,
            invoice.Shop?.ShopName ?? "LitePOS Shop",
            invoice.CustomerId,
            invoice.Customer?.CustomerName,
            invoice.Customer?.MobileNumber,
            invoice.CashierId,
            invoice.Cashier?.FullName ?? "Cashier",
            invoice.DeviceId,
            invoice.InvoiceDateUtc,
            invoice.SubTotal,
            invoice.DiscountAmount,
            invoice.TaxableAmount,
            invoice.TaxAmount,
            invoice.GrandTotal,
            invoice.PaidAmount,
            invoice.BalanceAmount,
            invoice.PaymentStatus,
            invoice.InvoiceStatus,
            invoice.SyncStatus,
            items,
            payments,
            invoice.CreatedAtUtc
        );
    }
}
