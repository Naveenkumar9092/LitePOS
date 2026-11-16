using System.Net;
using System.Net.Http.Json;
using BillingPOS.Application.DTOs;
using BillingPOS.Domain.Enums;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BillingPOS.Tests.IntegrationTests;

public class CompanyControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public CompanyControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SetupAndManageCompanyLifecycle_SucceedsEndToEnd()
    {
        var setupDto = new CompanySetupRequestDto
        {
            CompanyName = "Grand Food Court",
            LegalName = "Grand Foods Pvt Ltd",
            BusinessType = BusinessType.FoodCourt,
            GSTIN = "33AAAAA0000A1Z5",
            PAN = "AAAAA0000A",
            Email = "admin@grandfoods.com",
            MobileNumber = "9876543210",
            ShopName = "Express Counter 1",
            AddressLine1 = "Food Court Level 3, Phoenix Mall",
            City = "Chennai",
            State = "Tamil Nadu",
            Pincode = "600042",
            Country = "India",
            ContactNumber = "9876543210",
            ShopEmail = "counter1@grandfoods.com",
            CurrencyCode = "INR",
            TimeZone = "India Standard Time"
        };

        // 1. Setup Company (or if already setup, retrieve it)
        var setupResponse = await _client.PostAsJsonAsync("/api/v1/company/setup", setupDto);

        if (setupResponse.StatusCode == HttpStatusCode.Created)
        {
            var setupContent = await setupResponse.Content.ReadFromJsonAsync<ApiResponse<CompanyProfileDto>>();
            setupContent.Should().NotBeNull();
            setupContent!.Success.Should().BeTrue();
            setupContent.Data!.CompanyName.Should().Be("Grand Food Court");
            setupContent.Data.Shop!.ShopName.Should().Be("Express Counter 1");
        }
        else
        {
            // If already setup in test DB, it should reject duplicate with 400
            setupResponse.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        // 2. GET Profile
        var profileResponse = await _client.GetAsync("/api/v1/company/profile");
        profileResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var profileContent = await profileResponse.Content.ReadFromJsonAsync<ApiResponse<CompanyProfileDto>>();
        profileContent.Should().NotBeNull();
        profileContent!.Success.Should().BeTrue();
        profileContent.Data!.CompanyName.Should().NotBeNullOrEmpty();
        profileContent.Data.Shop.Should().NotBeNull();

        // 3. PUT Profile
        var updateProfileDto = new UpdateCompanyProfileDto
        {
            CompanyName = profileContent.Data.CompanyName,
            LegalName = "Updated Legal Entity",
            BusinessType = profileContent.Data.BusinessType,
            Email = profileContent.Data.Email,
            MobileNumber = profileContent.Data.MobileNumber,
            GSTIN = profileContent.Data.GSTIN
        };
        var updateResponse = await _client.PutAsJsonAsync("/api/v1/company/profile", updateProfileDto);
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // 4. GET Configuration
        var configResponse = await _client.GetAsync("/api/v1/company/configuration");
        configResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var configContent = await configResponse.Content.ReadFromJsonAsync<ApiResponse<ShopConfigurationDto>>();
        configContent.Should().NotBeNull();
        configContent!.Success.Should().BeTrue();
        configContent.Data!.CurrencyCode.Should().Be("INR");

        // 5. Duplicate Setup Prevention Check
        var dupResponse = await _client.PostAsJsonAsync("/api/v1/company/setup", setupDto);
        dupResponse.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}

