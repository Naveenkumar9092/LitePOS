using BillingPOS.Application.DTOs;
using BillingPOS.Domain.Enums;

namespace BillingPOS.Application.Interfaces;

public interface IBillingService
{
    Task<ApiResponse<InvoiceDto>> CreateInvoiceAsync(CreateInvoiceDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PagedInvoicesResultDto>> GetInvoicesAsync(int pageNumber = 1, int pageSize = 50, InvoiceStatus? status = null, string? search = null, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);
    Task<ApiResponse<InvoiceDto>> GetInvoiceByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<ApiResponse<InvoiceDto>> HoldBillAsync(HoldBillDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<List<InvoiceDto>>> GetHeldBillsAsync(CancellationToken cancellationToken = default);
    Task<ApiResponse<InvoiceDto>> ResumeBillAsync(long invoiceId, CancellationToken cancellationToken = default);
    Task<ApiResponse<bool>> CancelBillAsync(long invoiceId, string reason, CancellationToken cancellationToken = default);
    Task<ApiResponse<InvoiceDto>> ReprintBillAsync(long invoiceId, CancellationToken cancellationToken = default);
}

