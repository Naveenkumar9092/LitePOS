using BillingPOS.Application.DTOs;
using BillingPOS.Application.Exceptions;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using ValidationException = BillingPOS.Application.Exceptions.ValidationException;

namespace BillingPOS.Application.Services;

public class CompanyService : ICompanyService
{
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Shop> _shopRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IValidator<CompanySetupRequestDto> _setupValidator;
    private readonly IValidator<UpdateCompanyProfileDto> _profileValidator;
    private readonly IValidator<UpdateShopConfigurationDto> _shopConfigValidator;

    public CompanyService(
        IRepository<Company> companyRepository,
        IRepository<Shop> shopRepository,
        IUnitOfWork unitOfWork,
        IValidator<CompanySetupRequestDto> setupValidator,
        IValidator<UpdateCompanyProfileDto> profileValidator,
        IValidator<UpdateShopConfigurationDto> shopConfigValidator)
    {
        _companyRepository = companyRepository;
        _shopRepository = shopRepository;
        _unitOfWork = unitOfWork;
        _setupValidator = setupValidator;
        _profileValidator = profileValidator;
        _shopConfigValidator = shopConfigValidator;
    }

    public async Task<CompanyProfileDto> SetupCompanyAsync(CompanySetupRequestDto request, CancellationToken cancellationToken = default)
    {
        var validationResult = await _setupValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        // Enforce constraint: Only one company and one shop supported
        var existingCompany = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (existingCompany != null)
        {
            throw new AppException("Company and Shop have already been initialized. Only one company and one shop is supported.");
        }

        var company = new Company
        {
            CompanyName = request.CompanyName.Trim(),
            LegalName = request.LegalName?.Trim(),
            BusinessType = request.BusinessType,
            GSTIN = request.GSTIN?.Trim().ToUpperInvariant(),
            PAN = request.PAN?.Trim().ToUpperInvariant(),
            Email = request.Email.Trim().ToLowerInvariant(),
            MobileNumber = request.MobileNumber.Trim(),
            Website = request.Website?.Trim(),
            IsActive = true
        };

        var shop = new Shop
        {
            ShopName = request.ShopName.Trim(),
            AddressLine1 = request.AddressLine1.Trim(),
            AddressLine2 = request.AddressLine2?.Trim(),
            City = request.City.Trim(),
            State = request.State.Trim(),
            Pincode = request.Pincode.Trim(),
            Country = string.IsNullOrWhiteSpace(request.Country) ? "India" : request.Country.Trim(),
            ContactNumber = request.ContactNumber.Trim(),
            Email = request.ShopEmail.Trim().ToLowerInvariant(),
            TimeZone = string.IsNullOrWhiteSpace(request.TimeZone) ? "India Standard Time" : request.TimeZone.Trim(),
            CurrencyCode = string.IsNullOrWhiteSpace(request.CurrencyCode) ? "INR" : request.CurrencyCode.Trim().ToUpperInvariant(),
            InvoiceHeader = request.InvoiceHeader?.Trim(),
            InvoiceFooter = request.InvoiceFooter?.Trim(),
            IsActive = true,
            Company = company
        };

        company.Shop = shop;

        await _companyRepository.AddAsync(company, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToProfileDto(company, shop);
    }

    public async Task<CompanyProfileDto> GetCompanyProfileAsync(CancellationToken cancellationToken = default)
    {
        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            throw new NotFoundException("Company profile not found. Please complete company setup first.");
        }

        var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == company.Id && s.IsActive, cancellationToken);

        return MapToProfileDto(company, shop);
    }

    public async Task<CompanyProfileDto> UpdateCompanyProfileAsync(UpdateCompanyProfileDto request, CancellationToken cancellationToken = default)
    {
        var validationResult = await _profileValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            throw new NotFoundException("Company profile not found.");
        }

        company.CompanyName = request.CompanyName.Trim();
        company.LegalName = request.LegalName?.Trim();
        company.BusinessType = request.BusinessType;
        company.GSTIN = request.GSTIN?.Trim().ToUpperInvariant();
        company.PAN = request.PAN?.Trim().ToUpperInvariant();
        company.Email = request.Email.Trim().ToLowerInvariant();
        company.MobileNumber = request.MobileNumber.Trim();
        company.Website = request.Website?.Trim();

        _companyRepository.Update(company);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == company.Id && s.IsActive, cancellationToken);
        return MapToProfileDto(company, shop);
    }

    public async Task<ShopConfigurationDto> GetShopConfigurationAsync(CancellationToken cancellationToken = default)
    {
        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            throw new NotFoundException("Company profile not found.");
        }

        var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == company.Id && s.IsActive, cancellationToken);
        if (shop == null)
        {
            throw new NotFoundException("Shop details not found.");
        }

        return MapToShopConfigurationDto(company, shop);
    }

    public async Task<ShopConfigurationDto> UpdateShopConfigurationAsync(UpdateShopConfigurationDto request, CancellationToken cancellationToken = default)
    {
        var validationResult = await _shopConfigValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            throw new NotFoundException("Company profile not found.");
        }

        var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == company.Id && s.IsActive, cancellationToken);
        if (shop == null)
        {
            throw new NotFoundException("Shop details not found.");
        }

        // Update company business type if modified in shop configuration
        company.BusinessType = request.BusinessType;
        _companyRepository.Update(company);

        // Update shop properties
        shop.ShopName = request.ShopName.Trim();
        shop.AddressLine1 = request.AddressLine1.Trim();
        shop.AddressLine2 = request.AddressLine2?.Trim();
        shop.City = request.City.Trim();
        shop.State = request.State.Trim();
        shop.Pincode = request.Pincode.Trim();
        shop.ContactNumber = request.ContactNumber.Trim();
        shop.Email = request.Email.Trim().ToLowerInvariant();
        shop.TimeZone = string.IsNullOrWhiteSpace(request.TimeZone) ? "India Standard Time" : request.TimeZone.Trim();
        shop.CurrencyCode = string.IsNullOrWhiteSpace(request.CurrencyCode) ? "INR" : request.CurrencyCode.Trim().ToUpperInvariant();
        shop.InvoiceHeader = request.InvoiceHeader?.Trim();
        shop.InvoiceFooter = request.InvoiceFooter?.Trim();

        _shopRepository.Update(shop);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToShopConfigurationDto(company, shop);
    }

    public async Task<string> UploadLogoAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken = default)
    {
        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            throw new NotFoundException("Company profile not found. Please setup company first.");
        }

        var allowedExtensions = new[] { ".png", ".jpg", ".jpeg", ".webp", ".svg" };
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
        {
            throw new AppException("Invalid image file format. Allowed formats: PNG, JPG, JPEG, WEBP, SVG.");
        }

        var uploadDir = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "company");
        if (!Directory.Exists(uploadDir))
        {
            Directory.CreateDirectory(uploadDir);
        }

        var storageKey = $"logo_{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(uploadDir, storageKey);

        using (var outputStream = new FileStream(filePath, FileMode.Create))
        {
            await fileStream.CopyToAsync(outputStream, cancellationToken);
        }

        company.LogoStorageKey = storageKey;
        _companyRepository.Update(company);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return storageKey;
    }

    private static CompanyProfileDto MapToProfileDto(Company company, Shop? shop)
    {
        return new CompanyProfileDto
        {
            CompanyId = company.Id,
            CompanyName = company.CompanyName,
            LegalName = company.LegalName,
            BusinessType = company.BusinessType,
            GSTIN = company.GSTIN,
            PAN = company.PAN,
            Email = company.Email,
            MobileNumber = company.MobileNumber,
            Website = company.Website,
            LogoStorageKey = company.LogoStorageKey,
            IsActive = company.IsActive,
            CreatedAtUtc = company.CreatedAtUtc,
            UpdatedAtUtc = company.UpdatedAtUtc,
            Shop = shop == null ? null : new ShopDto
            {
                ShopId = shop.Id,
                CompanyId = shop.CompanyId,
                ShopName = shop.ShopName,
                AddressLine1 = shop.AddressLine1,
                AddressLine2 = shop.AddressLine2,
                City = shop.City,
                State = shop.State,
                Pincode = shop.Pincode,
                Country = shop.Country,
                ContactNumber = shop.ContactNumber,
                Email = shop.Email,
                TimeZone = shop.TimeZone,
                CurrencyCode = shop.CurrencyCode,
                InvoiceHeader = shop.InvoiceHeader,
                InvoiceFooter = shop.InvoiceFooter,
                IsActive = shop.IsActive
            }
        };
    }

    private static ShopConfigurationDto MapToShopConfigurationDto(Company company, Shop shop)
    {
        return new ShopConfigurationDto
        {
            ShopId = shop.Id,
            ShopName = shop.ShopName,
            BusinessType = company.BusinessType,
            TimeZone = shop.TimeZone,
            CurrencyCode = shop.CurrencyCode,
            InvoiceHeader = shop.InvoiceHeader,
            InvoiceFooter = shop.InvoiceFooter,
            AddressLine1 = shop.AddressLine1,
            AddressLine2 = shop.AddressLine2,
            City = shop.City,
            State = shop.State,
            Pincode = shop.Pincode,
            ContactNumber = shop.ContactNumber,
            Email = shop.Email
        };
    }
}
