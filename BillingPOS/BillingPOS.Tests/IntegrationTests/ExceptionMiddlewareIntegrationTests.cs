using System.Net;
using System.Net.Http.Json;
using BillingPOS.Application.DTOs;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BillingPOS.Tests.IntegrationTests;

public class ExceptionMiddlewareIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public ExceptionMiddlewareIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task RequestToNonExistentRoute_Returns404WithStandardApiResponseFormat()
    {
        // Act
        var response = await _client.GetAsync("/api/v1/non-existent-endpoint-test");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}

