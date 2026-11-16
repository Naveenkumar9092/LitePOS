using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IPaymentService
{
    Task<ApiResponse<PaymentTransactionDto>> ProcessPaymentAsync(ProcessPaymentDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<List<PaymentTransactionDto>>> ProcessSplitPaymentAsync(ProcessSplitPaymentDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PaymentTransactionDto>> ProcessRefundAsync(ProcessRefundDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<PagedPaymentsResultDto>> GetPaymentsAsync(PaymentFilterDto filter, CancellationToken cancellationToken = default);
    Task<ApiResponse<PaymentTransactionDto>> GetPaymentByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<ApiResponse<PaymentReconciliationDto>> GetPaymentReconciliationAsync(DateTime? date = null, CancellationToken cancellationToken = default);
    Task<ApiResponse<CashRegisterSessionDto>> OpenCashRegisterAsync(OpenCashRegisterDto dto, CancellationToken cancellationToken = default);
    Task<ApiResponse<CashRegisterSessionDto>> CloseCashRegisterAsync(CloseCashRegisterDto dto, CancellationToken cancellationToken = default);
}
