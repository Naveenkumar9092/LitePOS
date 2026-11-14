using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface ICompanyService
{
    Task<CompanyProfileDto> SetupCompanyAsync(CompanySetupRequestDto request, CancellationToken cancellationToken = default);
    Task<CompanyProfileDto> GetCompanyProfileAsync(CancellationToken cancellationToken = default);
    Task<CompanyProfileDto> UpdateCompanyProfileAsync(UpdateCompanyProfileDto request, CancellationToken cancellationToken = default);
    Task<ShopConfigurationDto> GetShopConfigurationAsync(CancellationToken cancellationToken = default);
    Task<ShopConfigurationDto> UpdateShopConfigurationAsync(UpdateShopConfigurationDto request, CancellationToken cancellationToken = default);
    Task<string> UploadLogoAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken = default);
}

