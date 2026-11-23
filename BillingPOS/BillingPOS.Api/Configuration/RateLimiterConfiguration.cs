using System.Threading.RateLimiting;
using BillingPOS.Application.DTOs;
using Microsoft.AspNetCore.RateLimiting;

namespace BillingPOS.Api.Configuration;

public static class RateLimiterConfiguration
{
    public const string AuthPolicy = "auth-policy";
    public const string GeneralPolicy = "general-policy";
    public const string SyncPolicy = "sync-policy";

    public static IServiceCollection AddCustomRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.OnRejected = async (context, token) =>
            {
                context.HttpContext.Response.ContentType = "application/json";
                var errorResponse = ApiResponse.FailureResult(
                    "Too many requests. Please slow down and try again later.",
                    new List<string> { "Rate limit exceeded. Please wait before making more requests." });
                await context.HttpContext.Response.WriteAsJsonAsync(errorResponse, cancellationToken: token);
            };

            // 1. Auth policy: max 10 requests per minute per IP to prevent password brute-forcing
            options.AddPolicy(AuthPolicy, httpContext =>
            {
                var clientIp = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-client";
                return RateLimitPartition.GetSlidingWindowLimiter(
                    partitionKey: clientIp,
                    factory: _ => new SlidingWindowRateLimiterOptions
                    {
                        PermitLimit = 10,
                        Window = TimeSpan.FromMinutes(1),
                        SegmentsPerWindow = 6,
                        QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                        QueueLimit = 0
                    });
            });

            // 2. Sync policy: max 30 sync requests per minute per IP
            options.AddPolicy(SyncPolicy, httpContext =>
            {
                var clientIp = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-client";
                return RateLimitPartition.GetSlidingWindowLimiter(
                    partitionKey: clientIp,
                    factory: _ => new SlidingWindowRateLimiterOptions
                    {
                        PermitLimit = 30,
                        Window = TimeSpan.FromMinutes(1),
                        SegmentsPerWindow = 6,
                        QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                        QueueLimit = 2
                    });
            });

            // 3. General policy: 150 requests per minute per IP for normal POS browsing & checkout
            options.AddPolicy(GeneralPolicy, httpContext =>
            {
                var clientIp = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-client";
                return RateLimitPartition.GetSlidingWindowLimiter(
                    partitionKey: clientIp,
                    factory: _ => new SlidingWindowRateLimiterOptions
                    {
                        PermitLimit = 150,
                        Window = TimeSpan.FromMinutes(1),
                        SegmentsPerWindow = 6,
                        QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                        QueueLimit = 5
                    });
            });
        });

        return services;
    }
}
