using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

public class CompanyController : BaseApiController
{
    private readonly ICompanyService _companyService;

    public CompanyController(ICompanyService companyService)
    {
        _companyService = companyService;
    }

    [HttpPost("setup")]
    public async Task<IActionResult> SetupCompany([FromBody] CompanySetupRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _companyService.SetupCompanyAsync(request, cancellationToken);
        return CreatedResponse("/api/v1/company/profile", result, "Company and Shop registered successfully.");
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        var result = await _companyService.GetCompanyProfileAsync(cancellationToken);
        return OkResponse(result, "Company profile retrieved successfully.");
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateCompanyProfileDto request, CancellationToken cancellationToken)
    {
        var result = await _companyService.UpdateCompanyProfileAsync(request, cancellationToken);
        return OkResponse(result, "Company profile updated successfully.");
    }

    [HttpGet("configuration")]
    public async Task<IActionResult> GetConfiguration(CancellationToken cancellationToken)
    {
        var result = await _companyService.GetShopConfigurationAsync(cancellationToken);
        return OkResponse(result, "Shop configuration retrieved successfully.");
    }

    [HttpPut("configuration")]
    public async Task<IActionResult> UpdateConfiguration([FromBody] UpdateShopConfigurationDto request, CancellationToken cancellationToken)
    {
        var result = await _companyService.UpdateShopConfigurationAsync(request, cancellationToken);
        return OkResponse(result, "Shop configuration updated successfully.");
    }

    [HttpPost("logo")]
    public async Task<IActionResult> UploadLogo(IFormFile file, CancellationToken cancellationToken)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequestResponse("Please provide an image file.");
        }

        if (file.Length > 2 * 1024 * 1024)
        {
            return BadRequestResponse("File size cannot exceed 2MB.");
        }

        using var stream = file.OpenReadStream();
        var storageKey = await _companyService.UploadLogoAsync(stream, file.FileName, file.ContentType, cancellationToken);

        return OkResponse(new { LogoStorageKey = storageKey, FileUrl = $"/uploads/company/{storageKey}" }, "Logo uploaded successfully.");
    }
}

