using BillingPOS.Application.DTOs;
using BillingPOS.Application.Validators;
using BillingPOS.Domain.Enums;
using FluentAssertions;

namespace BillingPOS.Tests.UnitTests.Application;

public class CompanySetupValidatorTests
{
    private readonly CompanySetupValidator _validator = new();

    private static CompanySetupRequestDto CreateValidRequest() => new()
    {
        CompanyName = "Royal Cafe & Bistro",
        LegalName = "Royal Food Ventures Pvt Ltd",
        BusinessType = BusinessType.Cafe,
        GSTIN = "33AAAAA0000A1Z5",
        PAN = "AAAAA0000A",
        Email = "info@royalcafe.com",
        MobileNumber = "9876543210",
        Website = "https://royalcafe.com",
        ShopName = "Royal Cafe Main Outlet",
        AddressLine1 = "123 Anna Salai",
        City = "Chennai",
        State = "Tamil Nadu",
        Pincode = "600002",
        Country = "India",
        ContactNumber = "9876543210",
        ShopEmail = "outlet@royalcafe.com",
        CurrencyCode = "INR",
        TimeZone = "India Standard Time"
    };

    [Fact]
    public async Task Validate_WhenValidRequest_PassesValidation()
    {
        var request = CreateValidRequest();
        var result = await _validator.ValidateAsync(request);

        result.IsValid.Should().BeTrue();
        result.Errors.Should().BeEmpty();
    }

    [Fact]
    public async Task Validate_WhenCompanyNameEmpty_FailsValidation()
    {
        var request = CreateValidRequest();
        request.CompanyName = "";

        var result = await _validator.ValidateAsync(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "CompanyName");
    }

    [Fact]
    public async Task Validate_WhenInvalidGstin_FailsValidation()
    {
        var request = CreateValidRequest();
        request.GSTIN = "INVALID_GSTIN_123";

        var result = await _validator.ValidateAsync(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "GSTIN");
    }

    [Fact]
    public async Task Validate_WhenInvalidMobileNumber_FailsValidation()
    {
        var request = CreateValidRequest();
        request.MobileNumber = "12345"; // Invalid phone

        var result = await _validator.ValidateAsync(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "MobileNumber");
    }
}

