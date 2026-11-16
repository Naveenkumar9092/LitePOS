using System.Net;
using System.Text.Json;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Exceptions;

namespace BillingPOS.Api.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var (statusCode, message, errors) = exception switch
        {
            ValidationException valEx => (
                (int)HttpStatusCode.BadRequest,
                valEx.Message,
                valEx.Errors),

            NotFoundException nfEx => (
                (int)HttpStatusCode.NotFound,
                nfEx.Message,
                new List<string> { nfEx.Message }),

            UnauthorizedException unauthEx => (
                (int)HttpStatusCode.Unauthorized,
                unauthEx.Message,
                new List<string> { unauthEx.Message }),

            ForbiddenException forbEx => (
                (int)HttpStatusCode.Forbidden,
                forbEx.Message,
                new List<string> { forbEx.Message }),

            AppException appEx => (
                appEx.StatusCode,
                appEx.Message,
                appEx.Errors),

            _ => (
                (int)HttpStatusCode.InternalServerError,
                "An unexpected internal server error occurred.",
                _environment.IsDevelopment() 
                    ? new List<string> { exception.Message, exception.StackTrace ?? string.Empty }
                    : new List<string> { "An error occurred while processing your request. Please contact support." })
        };

        context.Response.StatusCode = statusCode;

        var response = ApiResponse.FailureResult(message, errors);
        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        return context.Response.WriteAsync(json);
    }
}

