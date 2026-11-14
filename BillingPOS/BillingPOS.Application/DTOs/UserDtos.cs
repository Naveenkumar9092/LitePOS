namespace BillingPOS.Application.DTOs;

public record UserDto(
    long Id,
    long CompanyId,
    long? ShopId,
    string FullName,
    string Username,
    string? Email,
    string? MobileNumber,
    int RoleId,
    string RoleName,
    string? ShopName,
    bool IsActive,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);

public record CreateUserDto(
    string FullName,
    string Username,
    string? Email,
    string? MobileNumber,
    string Password,
    int RoleId,
    long? ShopId = null
);

public record UpdateUserDto(
    string FullName,
    string? Email,
    string? MobileNumber,
    int RoleId,
    long? ShopId = null
);

public record UpdateUserStatusDto(
    bool IsActive
);

public record LoginAuditLogDto(
    long Id,
    long? UserId,
    string UsernameAttempted,
    bool IsSuccess,
    string? IpAddress,
    string? DeviceId,
    string? FailureReason,
    DateTime AttemptedAtUtc
);

