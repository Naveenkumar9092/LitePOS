using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class CustomerService : ICustomerService
{
    private readonly IRepository<Customer> _customerRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IDateTimeService _dateTimeService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidator<CreateCustomerDto> _createCustomerValidator;
    private readonly IValidator<UpdateCustomerDto> _updateCustomerValidator;
    private readonly ILogger<CustomerService> _logger;

    public CustomerService(
        IRepository<Customer> customerRepository,
        IRepository<Invoice> invoiceRepository,
        IUnitOfWork unitOfWork,
        IDateTimeService dateTimeService,
        ICurrentUserService currentUserService,
        IValidator<CreateCustomerDto> createCustomerValidator,
        IValidator<UpdateCustomerDto> updateCustomerValidator,
        ILogger<CustomerService> logger)
    {
        _customerRepository = customerRepository;
        _invoiceRepository = invoiceRepository;
        _unitOfWork = unitOfWork;
        _dateTimeService = dateTimeService;
        _currentUserService = currentUserService;
        _createCustomerValidator = createCustomerValidator;
        _updateCustomerValidator = updateCustomerValidator;
        _logger = logger;
    }

    public async Task<PagedCustomersResultDto> GetCustomersAsync(CustomerFilterDto filter, CancellationToken cancellationToken = default)
    {
        var query = _customerRepository.Query()
            .Include(c => c.Invoices.Where(i => i.InvoiceStatus != InvoiceStatus.Cancelled))
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var s = filter.Search.Trim().ToLower();
            query = query.Where(c => c.CustomerName.ToLower().Contains(s) || c.MobileNumber.Contains(s));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var page = filter.PageNumber < 1 ? 1 : filter.PageNumber;
        var size = filter.PageSize < 1 ? 20 : filter.PageSize;

        var items = await query
            .OrderByDescending(c => c.CreatedAtUtc)
            .Skip((page - 1) * size)
            .Take(size)
            .ToListAsync(cancellationToken);

        var dtoList = items.Select(c =>
        {
            var activeInvoices = c.Invoices.ToList();
            var totalCountInv = activeInvoices.Count;
            var totalSpent = activeInvoices.Sum(i => i.GrandTotal);
            var lastVisit = activeInvoices.OrderByDescending(i => i.InvoiceDateUtc).FirstOrDefault()?.InvoiceDateUtc;

            return new CustomerDto(
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
                totalCountInv,
                totalSpent,
                lastVisit,
                c.IsActive,
                c.CreatedAtUtc
            );
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalCount / (double)size);

        return new PagedCustomersResultDto(dtoList, totalCount, page, size, totalPages);
    }

    public async Task<CustomerDto> GetCustomerByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var customer = await _customerRepository.Query()
            .Include(c => c.Invoices.Where(i => i.InvoiceStatus != InvoiceStatus.Cancelled))
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (customer == null)
        {
            throw new KeyNotFoundException($"Customer with ID {id} was not found.");
        }

        var activeInvoices = customer.Invoices.ToList();
        var totalCountInv = activeInvoices.Count;
        var totalSpent = activeInvoices.Sum(i => i.GrandTotal);
        var lastVisit = activeInvoices.OrderByDescending(i => i.InvoiceDateUtc).FirstOrDefault()?.InvoiceDateUtc;

        return new CustomerDto(
            customer.Id,
            customer.CustomerGuid,
            customer.CustomerName,
            customer.MobileNumber,
            customer.WhatsAppNumber,
            customer.Email,
            customer.Address,
            customer.GSTIN,
            customer.EmailConsent,
            customer.WhatsAppConsent,
            totalCountInv,
            totalSpent,
            lastVisit,
            customer.IsActive,
            customer.CreatedAtUtc
        );
    }

    public async Task<List<CustomerLookupDto>> LookupCustomersAsync(string query, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return new List<CustomerLookupDto>();
        }

        var s = query.Trim().ToLower();
        var customers = await _customerRepository.Query()
            .Where(c => c.IsActive && (c.MobileNumber.StartsWith(s) || c.MobileNumber.Contains(s) || c.CustomerName.ToLower().Contains(s)))
            .OrderBy(c => c.CustomerName)
            .Take(10)
            .Select(c => new CustomerLookupDto(
                c.Id,
                c.CustomerName,
                c.MobileNumber,
                c.GSTIN,
                c.Email,
                c.WhatsAppNumber
            ))
            .ToListAsync(cancellationToken);

        return customers;
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken cancellationToken = default)
    {
        await _createCustomerValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var existing = await _customerRepository.FirstOrDefaultAsync(c => c.MobileNumber == dto.MobileNumber, cancellationToken);
        if (existing != null)
        {
            throw new InvalidOperationException($"Customer with mobile number '{dto.MobileNumber}' already exists.");
        }

        var customer = new Customer
        {
            CustomerGuid = Guid.NewGuid(),
            CustomerName = dto.CustomerName.Trim(),
            MobileNumber = dto.MobileNumber.Trim(),
            WhatsAppNumber = !string.IsNullOrWhiteSpace(dto.WhatsAppNumber) ? dto.WhatsAppNumber.Trim() : dto.MobileNumber.Trim(),
            Email = !string.IsNullOrWhiteSpace(dto.Email) ? dto.Email.Trim() : null,
            Address = dto.Address?.Trim(),
            GSTIN = !string.IsNullOrWhiteSpace(dto.GSTIN) ? dto.GSTIN.Trim().ToUpperInvariant() : null,
            EmailConsent = dto.EmailConsent,
            WhatsAppConsent = dto.WhatsAppConsent,
            IsActive = true
        };

        await _customerRepository.AddAsync(customer, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Customer '{Name}' ({Mobile}) created successfully with ID #{Id}", customer.CustomerName, customer.MobileNumber, customer.Id);

        return new CustomerDto(
            customer.Id,
            customer.CustomerGuid,
            customer.CustomerName,
            customer.MobileNumber,
            customer.WhatsAppNumber,
            customer.Email,
            customer.Address,
            customer.GSTIN,
            customer.EmailConsent,
            customer.WhatsAppConsent,
            0,
            0m,
            null,
            customer.IsActive,
            customer.CreatedAtUtc
        );
    }

    public async Task<CustomerDto> UpdateCustomerAsync(long id, UpdateCustomerDto dto, CancellationToken cancellationToken = default)
    {
        await _updateCustomerValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var customer = await _customerRepository.Query()
            .Include(c => c.Invoices.Where(i => i.InvoiceStatus != InvoiceStatus.Cancelled))
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (customer == null)
        {
            throw new KeyNotFoundException($"Customer with ID {id} was not found.");
        }

        if (customer.MobileNumber != dto.MobileNumber)
        {
            var duplicate = await _customerRepository.FirstOrDefaultAsync(c => c.MobileNumber == dto.MobileNumber && c.Id != id, cancellationToken);
            if (duplicate != null)
            {
                throw new InvalidOperationException($"Mobile number '{dto.MobileNumber}' is already registered to another customer.");
            }
        }

        customer.CustomerName = dto.CustomerName.Trim();
        customer.MobileNumber = dto.MobileNumber.Trim();
        customer.WhatsAppNumber = !string.IsNullOrWhiteSpace(dto.WhatsAppNumber) ? dto.WhatsAppNumber.Trim() : dto.MobileNumber.Trim();
        customer.Email = !string.IsNullOrWhiteSpace(dto.Email) ? dto.Email.Trim() : null;
        customer.Address = dto.Address?.Trim();
        customer.GSTIN = !string.IsNullOrWhiteSpace(dto.GSTIN) ? dto.GSTIN.Trim().ToUpperInvariant() : null;
        customer.EmailConsent = dto.EmailConsent;
        customer.WhatsAppConsent = dto.WhatsAppConsent;
        customer.IsActive = dto.IsActive;

        _customerRepository.Update(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var activeInvoices = customer.Invoices.ToList();
        var totalCountInv = activeInvoices.Count;
        var totalSpent = activeInvoices.Sum(i => i.GrandTotal);
        var lastVisit = activeInvoices.OrderByDescending(i => i.InvoiceDateUtc).FirstOrDefault()?.InvoiceDateUtc;

        return new CustomerDto(
            customer.Id,
            customer.CustomerGuid,
            customer.CustomerName,
            customer.MobileNumber,
            customer.WhatsAppNumber,
            customer.Email,
            customer.Address,
            customer.GSTIN,
            customer.EmailConsent,
            customer.WhatsAppConsent,
            totalCountInv,
            totalSpent,
            lastVisit,
            customer.IsActive,
            customer.CreatedAtUtc
        );
    }

    public async Task<CustomerPurchaseHistoryDto> GetCustomerPurchaseHistoryAsync(long id, CancellationToken cancellationToken = default)
    {
        var customer = await _customerRepository.GetByIdAsync(id, cancellationToken);
        if (customer == null)
        {
            throw new KeyNotFoundException($"Customer with ID {id} was not found.");
        }

        var invoices = await _invoiceRepository.Query()
            .Include(i => i.Items)
            .Where(i => i.CustomerId == id && i.InvoiceStatus != InvoiceStatus.Cancelled)
            .OrderByDescending(i => i.InvoiceDateUtc)
            .ToListAsync(cancellationToken);

        var invoiceDtos = invoices.Select(i => new CustomerInvoiceItemDto(
            i.Id,
            i.InvoiceNumber,
            i.InvoiceDateUtc,
            i.GrandTotal,
            i.PaymentStatus.ToString(),
            i.Items.Sum(it => it.Quantity)
        )).ToList();

        var totalSpent = invoices.Sum(i => i.GrandTotal);
        var firstVisit = invoices.OrderBy(i => i.InvoiceDateUtc).FirstOrDefault()?.InvoiceDateUtc;
        var lastVisit = invoices.OrderByDescending(i => i.InvoiceDateUtc).FirstOrDefault()?.InvoiceDateUtc;

        return new CustomerPurchaseHistoryDto(
            customer.Id,
            customer.CustomerName,
            customer.MobileNumber,
            customer.GSTIN,
            invoices.Count,
            totalSpent,
            firstVisit,
            lastVisit,
            invoiceDtos
        );
    }
}

