namespace BillingPOS.Application.DTOs;

public record LoginRequestDto(
    string Username,
    string Password,
    string? DeviceId = null,
    string? DeviceName = null
);

public record LoginResponseDto(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAtUtc,
    UserDto User,
    List<string> Permissions
);

public record RefreshTokenRequestDto(
    string RefreshToken,
    string? DeviceId = null
);

public record LogoutRequestDto(
    string? RefreshToken = null
);

public record ChangePasswordDto(
    string CurrentPassword,
    string NewPassword,
    string ConfirmPassword
);

public record ForgotPasswordDto(
    string UsernameOrEmail
);

