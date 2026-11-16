using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IGstService
{
    Task<List<TaxDto>> GetTaxesAsync(bool? activeOnly = null, CancellationToken cancellationToken = default);
    Task<TaxDto> CreateTaxAsync(CreateTaxDto dto, CancellationToken cancellationToken = default);
    Task<TaxDto> UpdateTaxAsync(long id, UpdateTaxDto dto, CancellationToken cancellationToken = default);
    
    Task<List<HsnSacDto>> GetHsnSacsAsync(bool? activeOnly = null, CancellationToken cancellationToken = default);
    Task<HsnSacDto> CreateOrUpdateHsnSacAsync(CreateHsnSacDto dto, CancellationToken cancellationToken = default);
    
    Task<GstConfigurationDto> GetGstConfigurationAsync(CancellationToken cancellationToken = default);
    Task<GstConfigurationDto> UpdateGstConfigurationAsync(UpdateGstConfigurationDto dto, CancellationToken cancellationToken = default);
    
    Task<GstSummaryDto> GetGstSummaryAsync(DateTime? fromUtc, DateTime? toUtc, CancellationToken cancellationToken = default);
    
    Task<CreditNoteDto> CreateCreditNoteAsync(CreateCreditNoteDto dto, CancellationToken cancellationToken = default);
    Task<List<CreditNoteDto>> GetCreditNotesAsync(long? invoiceId = null, string? noteType = null, CancellationToken cancellationToken = default);
    Task<CreditNoteDto> GetCreditNoteByIdAsync(long id, CancellationToken cancellationToken = default);
}

