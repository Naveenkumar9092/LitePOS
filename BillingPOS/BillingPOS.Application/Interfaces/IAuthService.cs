using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IAuthService
{
    Task<ApiResponse<LoginResponseDto>> LoginAsync(
        LoginRequestDto request, 
        string? ipAddress = null, 
        string? userAgent = null, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<LoginResponseDto>> RefreshTokenAsync(
        RefreshTokenRequestDto request, 
        string? ipAddress = null, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<bool>> LogoutAsync(
        LogoutRequestDto request, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<bool>> ChangePasswordAsync(
        long userId, 
        ChangePasswordDto request, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<bool>> ForgotPasswordAsync(
        ForgotPasswordDto request, 
        CancellationToken cancellationToken = default);
}

