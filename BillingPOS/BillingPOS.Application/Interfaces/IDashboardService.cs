using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IDashboardService
{
    Task<ApiResponse<SAdminDashboardDto>> GetSAdminDashboardAsync(CancellationToken cancellationToken = default);
    
    Task<ApiResponse<AdminDashboardDto>> GetAdminDashboardAsync(
        DateTime? date = null, 
        CancellationToken cancellationToken = default);
    
    Task<ApiResponse<CashierDashboardDto>> GetCashierDashboardAsync(
        long? cashierId = null, 
        DateTime? date = null, 
        CancellationToken cancellationToken = default);
    
    Task<ApiResponse<SalesSummaryDto>> GetSalesSummaryAsync(
        string period = "today", 
        CancellationToken cancellationToken = default);
    
    Task<ApiResponse<PaymentSummaryDto>> GetPaymentSummaryAsync(
        string period = "today", 
        CancellationToken cancellationToken = default);
    
    Task<ApiResponse<List<RecentTransactionDto>>> GetRecentTransactionsAsync(
        int limit = 10, 
        long? cashierId = null, 
        CancellationToken cancellationToken = default);
}

