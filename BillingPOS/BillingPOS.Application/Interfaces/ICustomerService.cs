using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface ICustomerService
{
    Task<PagedCustomersResultDto> GetCustomersAsync(CustomerFilterDto filter, CancellationToken cancellationToken = default);
    Task<CustomerDto> GetCustomerByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<List<CustomerLookupDto>> LookupCustomersAsync(string query, CancellationToken cancellationToken = default);
    Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken cancellationToken = default);
    Task<CustomerDto> UpdateCustomerAsync(long id, UpdateCustomerDto dto, CancellationToken cancellationToken = default);
    Task<CustomerPurchaseHistoryDto> GetCustomerPurchaseHistoryAsync(long id, CancellationToken cancellationToken = default);
}

