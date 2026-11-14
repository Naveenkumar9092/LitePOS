using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Enums;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BillingPOS.Application.Services;

public class GstService : IGstService
{
    private readonly IRepository<Tax> _taxRepository;
    private readonly IRepository<HsnSac> _hsnSacRepository;
    private readonly IRepository<GstConfiguration> _gstConfigRepository;
    private readonly IRepository<CreditNote> _creditNoteRepository;
    private readonly IRepository<Invoice> _invoiceRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IDateTimeService _dateTimeService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidator<CreateTaxDto> _createTaxValidator;
    private readonly IValidator<UpdateTaxDto> _updateTaxValidator;
    private readonly IValidator<CreateHsnSacDto> _createHsnSacValidator;
    private readonly IValidator<UpdateGstConfigurationDto> _updateGstConfigValidator;
    private readonly IValidator<CreateCreditNoteDto> _createCreditNoteValidator;
    private readonly ILogger<GstService> _logger;

    public GstService(
        IRepository<Tax> taxRepository,
        IRepository<HsnSac> hsnSacRepository,
        IRepository<GstConfiguration> gstConfigRepository,
        IRepository<CreditNote> creditNoteRepository,
        IRepository<Invoice> invoiceRepository,
        IRepository<Product> productRepository,
        IUnitOfWork unitOfWork,
        IDateTimeService dateTimeService,
        ICurrentUserService currentUserService,
        IValidator<CreateTaxDto> createTaxValidator,
        IValidator<UpdateTaxDto> updateTaxValidator,
        IValidator<CreateHsnSacDto> createHsnSacValidator,
        IValidator<UpdateGstConfigurationDto> updateGstConfigValidator,
        IValidator<CreateCreditNoteDto> createCreditNoteValidator,
        ILogger<GstService> logger)
    {
        _taxRepository = taxRepository;
        _hsnSacRepository = hsnSacRepository;
        _gstConfigRepository = gstConfigRepository;
        _creditNoteRepository = creditNoteRepository;
        _invoiceRepository = invoiceRepository;
        _productRepository = productRepository;
        _unitOfWork = unitOfWork;
        _dateTimeService = dateTimeService;
        _currentUserService = currentUserService;
        _createTaxValidator = createTaxValidator;
        _updateTaxValidator = updateTaxValidator;
        _createHsnSacValidator = createHsnSacValidator;
        _updateGstConfigValidator = updateGstConfigValidator;
        _createCreditNoteValidator = createCreditNoteValidator;
        _logger = logger;
    }

    public async Task<List<TaxDto>> GetTaxesAsync(bool? activeOnly = null, CancellationToken cancellationToken = default)
    {
        var query = _taxRepository.Query().Where(t => !t.IsDeleted);
        if (activeOnly.HasValue && activeOnly.Value)
        {
            query = query.Where(t => t.IsActive);
        }

        var taxes = await query.OrderBy(t => t.RatePercentage).ToListAsync(cancellationToken);
        return taxes.Select(t => new TaxDto(
            t.Id,
            t.TaxName,
            t.RatePercentage,
            t.CgstPercentage,
            t.SgstPercentage,
            t.IgstPercentage,
            t.IsActive,
            t.IsDefault,
            t.IsTaxInclusiveDefault
        )).ToList();
    }

    public async Task<TaxDto> CreateTaxAsync(CreateTaxDto dto, CancellationToken cancellationToken = default)
    {
        await _createTaxValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var cgst = Math.Round(dto.RatePercentage / 2m, 2);
        var sgst = dto.RatePercentage - cgst;
        var igst = dto.RatePercentage;

        if (dto.IsDefault)
        {
            var existingDefaults = await _taxRepository.FindAsync(t => t.IsDefault && !t.IsDeleted, cancellationToken);
            foreach (var def in existingDefaults)
            {
                def.IsDefault = false;
                _taxRepository.Update(def);
            }
        }

        var tax = new Tax
        {
            CompanyId = 1,
            TaxName = dto.TaxName,
            RatePercentage = dto.RatePercentage,
            CgstPercentage = cgst,
            SgstPercentage = sgst,
            IgstPercentage = igst,
            IsDefault = dto.IsDefault,
            IsTaxInclusiveDefault = dto.IsTaxInclusiveDefault,
            IsActive = true
        };

        await _taxRepository.AddAsync(tax, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Tax rate {TaxName} ({Rate}%) created successfully", tax.TaxName, tax.RatePercentage);

        return new TaxDto(tax.Id, tax.TaxName, tax.RatePercentage, tax.CgstPercentage, tax.SgstPercentage, tax.IgstPercentage, tax.IsActive, tax.IsDefault, tax.IsTaxInclusiveDefault);
    }

    public async Task<TaxDto> UpdateTaxAsync(long id, UpdateTaxDto dto, CancellationToken cancellationToken = default)
    {
        await _updateTaxValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var tax = await _taxRepository.GetByIdAsync(id, cancellationToken);
        if (tax == null || tax.IsDeleted)
        {
            throw new KeyNotFoundException($"Tax rate with ID {id} was not found.");
        }

        if (dto.IsDefault && !tax.IsDefault)
        {
            var existingDefaults = await _taxRepository.FindAsync(t => t.IsDefault && !t.IsDeleted, cancellationToken);
            foreach (var def in existingDefaults)
            {
                def.IsDefault = false;
                _taxRepository.Update(def);
            }
        }

        var cgst = Math.Round(dto.RatePercentage / 2m, 2);
        var sgst = dto.RatePercentage - cgst;
        var igst = dto.RatePercentage;

        tax.TaxName = dto.TaxName;
        tax.RatePercentage = dto.RatePercentage;
        tax.CgstPercentage = cgst;
        tax.SgstPercentage = sgst;
        tax.IgstPercentage = igst;
        tax.IsActive = dto.IsActive;
        tax.IsDefault = dto.IsDefault;
        tax.IsTaxInclusiveDefault = dto.IsTaxInclusiveDefault;

        _taxRepository.Update(tax);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new TaxDto(tax.Id, tax.TaxName, tax.RatePercentage, tax.CgstPercentage, tax.SgstPercentage, tax.IgstPercentage, tax.IsActive, tax.IsDefault, tax.IsTaxInclusiveDefault);
    }

    public async Task<List<HsnSacDto>> GetHsnSacsAsync(bool? activeOnly = null, CancellationToken cancellationToken = default)
    {
        var query = _hsnSacRepository.Query().Where(h => !h.IsDeleted);
        if (activeOnly.HasValue && activeOnly.Value)
        {
            query = query.Where(h => h.IsActive);
        }

        var list = await query.OrderBy(h => h.Code).ToListAsync(cancellationToken);
        return list.Select(h => new HsnSacDto(
            h.Id,
            h.Code,
            h.Description,
            h.Type,
            h.DefaultGstRate,
            h.IsActive
        )).ToList();
    }

    public async Task<HsnSacDto> CreateOrUpdateHsnSacAsync(CreateHsnSacDto dto, CancellationToken cancellationToken = default)
    {
        await _createHsnSacValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var existing = await _hsnSacRepository.FirstOrDefaultAsync(h => h.Code == dto.Code && !h.IsDeleted, cancellationToken);
        if (existing != null)
        {
            existing.Description = dto.Description;
            existing.Type = dto.Type.ToUpperInvariant();
            existing.DefaultGstRate = dto.DefaultGstRate;
            existing.IsActive = dto.IsActive;
            _hsnSacRepository.Update(existing);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return new HsnSacDto(existing.Id, existing.Code, existing.Description, existing.Type, existing.DefaultGstRate, existing.IsActive);
        }

        var hsn = new HsnSac
        {
            CompanyId = 1,
            Code = dto.Code,
            Description = dto.Description,
            Type = dto.Type.ToUpperInvariant(),
            DefaultGstRate = dto.DefaultGstRate,
            IsActive = dto.IsActive
        };

        await _hsnSacRepository.AddAsync(hsn, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new HsnSacDto(hsn.Id, hsn.Code, hsn.Description, hsn.Type, hsn.DefaultGstRate, hsn.IsActive);
    }

    public async Task<GstConfigurationDto> GetGstConfigurationAsync(CancellationToken cancellationToken = default)
    {
        var config = await _gstConfigRepository.FirstOrDefaultAsync(c => !c.IsDeleted, cancellationToken);
        if (config == null)
        {
            config = new GstConfiguration();
            await _gstConfigRepository.AddAsync(config, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return new GstConfigurationDto(
            config.Id,
            config.GSTIN,
            config.LegalName,
            config.TradeName,
            config.StateName,
            config.StateCode,
            config.IsCompositionScheme,
            config.DefaultPricingIsTaxInclusive,
            config.InvoiceTermsAndConditions,
            config.InvoiceHeader,
            config.InvoiceFooter,
            config.ShowHsnSummaryOnReceipt,
            config.ShowTaxBreakupOnReceipt
        );
    }

    public async Task<GstConfigurationDto> UpdateGstConfigurationAsync(UpdateGstConfigurationDto dto, CancellationToken cancellationToken = default)
    {
        await _updateGstConfigValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var config = await _gstConfigRepository.FirstOrDefaultAsync(c => !c.IsDeleted, cancellationToken);
        if (config == null)
        {
            config = new GstConfiguration();
            await _gstConfigRepository.AddAsync(config, cancellationToken);
        }

        config.GSTIN = dto.GSTIN;
        config.LegalName = dto.LegalName;
        config.TradeName = dto.TradeName;
        config.StateName = dto.StateName;
        config.StateCode = dto.StateCode;
        config.IsCompositionScheme = dto.IsCompositionScheme;
        config.DefaultPricingIsTaxInclusive = dto.DefaultPricingIsTaxInclusive;
        config.InvoiceTermsAndConditions = dto.InvoiceTermsAndConditions;
        config.InvoiceHeader = dto.InvoiceHeader;
        config.InvoiceFooter = dto.InvoiceFooter;
        config.ShowHsnSummaryOnReceipt = dto.ShowHsnSummaryOnReceipt;
        config.ShowTaxBreakupOnReceipt = dto.ShowTaxBreakupOnReceipt;

        _gstConfigRepository.Update(config);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new GstConfigurationDto(
            config.Id,
            config.GSTIN,
            config.LegalName,
            config.TradeName,
            config.StateName,
            config.StateCode,
            config.IsCompositionScheme,
            config.DefaultPricingIsTaxInclusive,
            config.InvoiceTermsAndConditions,
            config.InvoiceHeader,
            config.InvoiceFooter,
            config.ShowHsnSummaryOnReceipt,
            config.ShowTaxBreakupOnReceipt
        );
    }

    public async Task<CreditNoteDto> CreateCreditNoteAsync(CreateCreditNoteDto dto, CancellationToken cancellationToken = default)
    {
        await _createCreditNoteValidator.ValidateAndThrowAsync(dto, cancellationToken);

        var invoice = await _invoiceRepository.Query()
            .Include(i => i.Items)
            .Include(i => i.Customer)
            .FirstOrDefaultAsync(i => i.Id == dto.InvoiceId, cancellationToken);

        if (invoice == null)
        {
            throw new KeyNotFoundException($"Invoice #{dto.InvoiceId} not found.");
        }

        var config = await GetGstConfigurationAsync(cancellationToken);
        var noteType = dto.NoteType.Equals("DebitNote", StringComparison.OrdinalIgnoreCase) ? "DebitNote" : "CreditNote";
        var prefix = noteType == "DebitNote" ? "DN" : "CN";
        var count = await _creditNoteRepository.CountAsync(c => c.NoteType == noteType, cancellationToken) + 1;
        var number = $"{prefix}-{_dateTimeService.UtcNow:yyyyMM}-{count:D4}";

        var creditNote = new CreditNote
        {
            CreditNoteGuid = Guid.NewGuid(),
            CreditNoteNumber = number,
            CompanyId = invoice.CompanyId,
            ShopId = invoice.ShopId,
            InvoiceId = invoice.Id,
            InvoiceNumberSnapshot = invoice.InvoiceNumber,
            CustomerId = invoice.CustomerId,
            CustomerNameSnapshot = invoice.Customer?.CustomerName,
            CustomerGstinSnapshot = invoice.Customer?.GSTIN,
            CreditNoteDateUtc = _dateTimeService.UtcNow,
            Reason = dto.Reason,
            NoteType = noteType,
            Status = "Issued"
        };

        decimal totalTaxable = 0m;
        decimal totalTax = 0m;
        decimal grandTotal = 0m;

        var itemsToProcess = dto.Items ?? new List<CreateCreditNoteItemDto>();
        if (!itemsToProcess.Any())
        {
            // Default to all invoice items if none specified
            foreach (var invItem in invoice.Items)
            {
                itemsToProcess.Add(new CreateCreditNoteItemDto(invItem.ProductId, invItem.Quantity, invItem.UnitPrice, dto.Reason));
            }
        }

        foreach (var itemDto in itemsToProcess)
        {
            var product = await _productRepository.GetByIdAsync(itemDto.ProductId, cancellationToken);
            var productName = product?.ProductName ?? "Item";
            var hsnCode = product?.HSNCode ?? "2106";
            var invItem = invoice.Items.FirstOrDefault(i => i.ProductId == itemDto.ProductId);
            var unitPrice = itemDto.UnitPrice ?? invItem?.UnitPrice ?? product?.SellingPrice ?? 0m;
            var taxRate = invItem?.TaxPercentage ?? product?.TaxPercentage ?? 5.0m;

            decimal lineTotal;
            decimal taxable;
            decimal taxAmount;

            if (config.DefaultPricingIsTaxInclusive)
            {
                lineTotal = Math.Round(itemDto.Quantity * unitPrice, 2);
                taxable = Math.Round(lineTotal / (1m + (taxRate / 100m)), 2);
                taxAmount = lineTotal - taxable;
            }
            else
            {
                taxable = Math.Round(itemDto.Quantity * unitPrice, 2);
                taxAmount = Math.Round(taxable * (taxRate / 100m), 2);
                lineTotal = taxable + taxAmount;
            }

            totalTaxable += taxable;
            totalTax += taxAmount;
            grandTotal += lineTotal;

            creditNote.Items.Add(new CreditNoteItem
            {
                ProductId = itemDto.ProductId,
                ProductNameSnapshot = productName,
                HSNCodeSnapshot = hsnCode,
                Quantity = itemDto.Quantity,
                UnitPrice = unitPrice,
                TaxPercentage = taxRate,
                TaxAmount = taxAmount,
                LineTotal = lineTotal,
                Reason = itemDto.Reason ?? dto.Reason
            });
        }

        // Intra-state vs Inter-state calculation
        var isInterstate = !string.IsNullOrWhiteSpace(invoice.Customer?.GSTIN) &&
                           invoice.Customer.GSTIN.Length >= 2 &&
                           !invoice.Customer.GSTIN.StartsWith(config.StateCode, StringComparison.OrdinalIgnoreCase);

        creditNote.TaxableAmount = totalTaxable;
        creditNote.TotalTaxAmount = totalTax;
        creditNote.GrandTotal = grandTotal;

        if (isInterstate)
        {
            creditNote.IgstAmount = totalTax;
            creditNote.CgstAmount = 0m;
            creditNote.SgstAmount = 0m;
        }
        else
        {
            creditNote.CgstAmount = Math.Round(totalTax / 2m, 2);
            creditNote.SgstAmount = totalTax - creditNote.CgstAmount;
            creditNote.IgstAmount = 0m;
        }

        await _creditNoteRepository.AddAsync(creditNote, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("{NoteType} #{Number} issued against invoice #{InvoiceNumber} for amount {GrandTotal}",
            creditNote.NoteType, creditNote.CreditNoteNumber, creditNote.InvoiceNumberSnapshot, creditNote.GrandTotal);

        return MapToCreditNoteDto(creditNote);
    }

    public async Task<List<CreditNoteDto>> GetCreditNotesAsync(long? invoiceId = null, string? noteType = null, CancellationToken cancellationToken = default)
    {
        var query = _creditNoteRepository.Query().Include(c => c.Items).Where(c => !c.IsDeleted);

        if (invoiceId.HasValue)
        {
            query = query.Where(c => c.InvoiceId == invoiceId.Value);
        }

        if (!string.IsNullOrWhiteSpace(noteType))
        {
            query = query.Where(c => c.NoteType == noteType);
        }

        var list = await query.OrderByDescending(c => c.CreditNoteDateUtc).ToListAsync(cancellationToken);
        return list.Select(MapToCreditNoteDto).ToList();
    }

    public async Task<CreditNoteDto> GetCreditNoteByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var creditNote = await _creditNoteRepository.Query()
            .Include(c => c.Items)
            .FirstOrDefaultAsync(c => c.Id == id && !c.IsDeleted, cancellationToken);

        if (creditNote == null)
        {
            throw new KeyNotFoundException($"Credit Note with ID {id} not found.");
        }

        return MapToCreditNoteDto(creditNote);
    }

    public async Task<GstSummaryDto> GetGstSummaryAsync(DateTime? fromUtc, DateTime? toUtc, CancellationToken cancellationToken = default)
    {
        var config = await GetGstConfigurationAsync(cancellationToken);
        var from = fromUtc ?? new DateTime(_dateTimeService.UtcNow.Year, _dateTimeService.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var to = toUtc ?? _dateTimeService.UtcNow;

        var invoices = await _invoiceRepository.Query()
            .Include(i => i.Customer)
            .Include(i => i.Items)
            .Where(i => i.InvoiceDateUtc >= from && i.InvoiceDateUtc <= to && i.InvoiceStatus != InvoiceStatus.Cancelled)
            .ToListAsync(cancellationToken);

        var b2bInvoices = invoices.Where(i => !string.IsNullOrWhiteSpace(i.Customer?.GSTIN)).ToList();
        var b2cInvoices = invoices.Where(i => string.IsNullOrWhiteSpace(i.Customer?.GSTIN)).ToList();

        // B2C aggregates
        var b2cTotalInvoices = b2cInvoices.Count;
        var b2cTaxable = b2cInvoices.Sum(i => i.TaxableAmount);
        var b2cTotalTax = b2cInvoices.Sum(i => i.TaxAmount);
        var b2cCgst = Math.Round(b2cTotalTax / 2m, 2);
        var b2cSgst = b2cTotalTax - b2cCgst;
        var b2cIgst = 0m;
        var b2cGrandTotal = b2cInvoices.Sum(i => i.GrandTotal);

        var b2cSummary = new B2cSummaryDto(b2cTotalInvoices, b2cTaxable, b2cCgst, b2cSgst, b2cIgst, b2cTotalTax, b2cGrandTotal);

        // B2B items and aggregates
        var b2bList = new List<B2bInvoiceSummaryDto>();
        decimal b2bTaxable = 0m;
        decimal b2bTotalTax = 0m;
        decimal b2bCgst = 0m;
        decimal b2bSgst = 0m;
        decimal b2bIgst = 0m;
        decimal b2bGrandTotal = 0m;

        foreach (var inv in b2bInvoices)
        {
            var isInterstate = inv.Customer!.GSTIN!.Length >= 2 && !inv.Customer.GSTIN.StartsWith(config.StateCode, StringComparison.OrdinalIgnoreCase);
            decimal cgst = 0m, sgst = 0m, igst = 0m;
            if (isInterstate)
            {
                igst = inv.TaxAmount;
            }
            else
            {
                cgst = Math.Round(inv.TaxAmount / 2m, 2);
                sgst = inv.TaxAmount - cgst;
            }

            b2bTaxable += inv.TaxableAmount;
            b2bTotalTax += inv.TaxAmount;
            b2bCgst += cgst;
            b2bSgst += sgst;
            b2bIgst += igst;
            b2bGrandTotal += inv.GrandTotal;

            b2bList.Add(new B2bInvoiceSummaryDto(
                inv.Id,
                inv.InvoiceNumber,
                inv.InvoiceDateUtc,
                inv.Customer.CustomerName,
                inv.Customer.GSTIN,
                inv.TaxableAmount,
                cgst,
                sgst,
                igst,
                inv.TaxAmount,
                inv.GrandTotal
            ));
        }

        var b2bSummary = new B2bSummaryDto(b2bInvoices.Count, b2bTaxable, b2bCgst, b2bSgst, b2bIgst, b2bTotalTax, b2bGrandTotal, b2bList);

        // HSN-wise Summary
        var allItems = invoices.SelectMany(i => i.Items).ToList();
        var hsnGroups = allItems.GroupBy(i => i.ProductNameSnapshot).ToList(); // Grouped by item snapshot
        var hsnSummary = new List<HsnSummaryItemDto>();

        foreach (var grp in hsnGroups)
        {
            var totalQty = grp.Sum(x => x.Quantity);
            var taxable = grp.Sum(x => x.LineTotal - x.TaxAmount);
            var taxAmount = grp.Sum(x => x.TaxAmount);
            var cgst = Math.Round(taxAmount / 2m, 2);
            var sgst = taxAmount - cgst;

            hsnSummary.Add(new HsnSummaryItemDto(
                "2106", // Standard Cafe/Food court HSN
                grp.Key,
                totalQty,
                taxable,
                cgst,
                sgst,
                0m,
                taxAmount
            ));
        }

        // Credit Notes Summary
        var creditNotes = await _creditNoteRepository.Query()
            .Where(c => c.CreditNoteDateUtc >= from && c.CreditNoteDateUtc <= to && !c.IsDeleted && c.NoteType == "CreditNote")
            .ToListAsync(cancellationToken);

        var cnCount = creditNotes.Count;
        var cnTaxable = creditNotes.Sum(c => c.TaxableAmount);
        var cnTax = creditNotes.Sum(c => c.TotalTaxAmount);
        var netLiability = (b2cTaxable + b2bTaxable) - cnTaxable;

        var cnSummary = new CreditNotesSummaryDto(cnCount, cnTaxable, cnTax, netLiability);

        return new GstSummaryDto(
            from,
            to,
            config.GSTIN,
            config.LegalName,
            config.StateCode,
            b2cSummary,
            b2bSummary,
            hsnSummary,
            cnSummary
        );
    }

    private static CreditNoteDto MapToCreditNoteDto(CreditNote entity)
    {
        return new CreditNoteDto(
            entity.Id,
            entity.CreditNoteGuid,
            entity.CreditNoteNumber,
            entity.InvoiceId,
            entity.InvoiceNumberSnapshot,
            entity.CustomerId,
            entity.CustomerNameSnapshot,
            entity.CustomerGstinSnapshot,
            entity.CreditNoteDateUtc,
            entity.Reason,
            entity.NoteType,
            entity.TaxableAmount,
            entity.CgstAmount,
            entity.SgstAmount,
            entity.IgstAmount,
            entity.TotalTaxAmount,
            entity.GrandTotal,
            entity.Status,
            entity.Items.Select(i => new CreditNoteItemDto(
                i.ProductId,
                i.ProductNameSnapshot,
                i.HSNCodeSnapshot,
                i.Quantity,
                i.UnitPrice,
                i.TaxPercentage,
                i.TaxAmount,
                i.LineTotal,
                i.Reason
            )).ToList()
        );
    }
}

