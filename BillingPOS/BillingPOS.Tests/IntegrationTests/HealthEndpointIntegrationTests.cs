using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using BillingPOS.Application.DTOs;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BillingPOS.Tests.IntegrationTests;

public class HealthEndpointIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public HealthEndpointIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task PingEndpoint_ReturnsSuccessStatusCodeAndValidResponse()
    {
        // Act
        var response = await _client.GetAsync("/api/v1/health/ping");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<JsonElement>>();
        content.Should().NotBeNull();
        content!.Success.Should().BeTrue();
        content.Message.Should().Be("Pong response");
        content.Data.GetProperty("status").GetString().Should().Be("Pong");
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsStandardApiResponse()
    {
        // Act
        var response = await _client.GetAsync("/api/v1/health");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<HealthCheckDto>>();
        content.Should().NotBeNull();
        content!.Success.Should().BeTrue();
        content.Data.Should().NotBeNull();
        content.Data!.Version.Should().NotBeNullOrEmpty();
    }
}

