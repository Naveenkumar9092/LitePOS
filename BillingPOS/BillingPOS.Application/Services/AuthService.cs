using BillingPOS.Application.Constants;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using ValidationException = BillingPOS.Application.Exceptions.ValidationException;

namespace BillingPOS.Application.Services;

public class AuthService : IAuthService
{
    private readonly IRepository<User> _userRepository;
    private readonly IRepository<Role, int> _roleRepository;
    private readonly IRepository<RolePermission, int> _rolePermissionRepository;
    private readonly IRepository<Permission, int> _permissionRepository;
    private readonly IRepository<RefreshToken> _refreshTokenRepository;
    private readonly IRepository<UserSession> _sessionRepository;
    private readonly IRepository<LoginAuditLog> _auditLogRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<LoginRequestDto> _loginValidator;
    private readonly IValidator<ChangePasswordDto> _changePasswordValidator;
    private readonly IValidator<ForgotPasswordDto> _forgotPasswordValidator;

    public AuthService(
        IRepository<User> userRepository,
        IRepository<Role, int> roleRepository,
        IRepository<RolePermission, int> rolePermissionRepository,
        IRepository<Permission, int> permissionRepository,
        IRepository<RefreshToken> refreshTokenRepository,
        IRepository<UserSession> sessionRepository,
        IRepository<LoginAuditLog> auditLogRepository,
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService,
        IValidator<LoginRequestDto> loginValidator,
        IValidator<ChangePasswordDto> changePasswordValidator,
        IValidator<ForgotPasswordDto> forgotPasswordValidator)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _rolePermissionRepository = rolePermissionRepository;
        _permissionRepository = permissionRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _sessionRepository = sessionRepository;
        _auditLogRepository = auditLogRepository;
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
        _loginValidator = loginValidator;
        _changePasswordValidator = changePasswordValidator;
        _forgotPasswordValidator = forgotPasswordValidator;
    }

    public async Task<ApiResponse<LoginResponseDto>> LoginAsync(
        LoginRequestDto request, 
        string? ipAddress = null, 
        string? userAgent = null, 
        CancellationToken cancellationToken = default)
    {
        var validationResult = await _loginValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var normalizedInput = request.Username.Trim();

        // Find user by Username or Mobile number
        var user = await _userRepository.Query()
            .Include(u => u.Role)
            .Include(u => u.Shop)
            .FirstOrDefaultAsync(u => 
                u.Username.ToLower() == normalizedInput.ToLower() || 
                u.MobileNumber == normalizedInput, 
                cancellationToken);

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            await LogLoginAttemptAsync(user?.Id, normalizedInput, false, ipAddress, userAgent, request.DeviceId, "Invalid credentials", cancellationToken);
            return ApiResponse<LoginResponseDto>.Fail(
                "Invalid username or password.", 
                ["The credentials provided are incorrect."]);
        }

        if (!user.IsActive)
        {
            await LogLoginAttemptAsync(user.Id, normalizedInput, false, ipAddress, userAgent, request.DeviceId, "User account is inactive", cancellationToken);
            return ApiResponse<LoginResponseDto>.Fail(
                "User account is deactivated.", 
                ["Your account has been deactivated. Please contact your system administrator."]);
        }

        // Load permissions
        var permissions = await GetPermissionsForRoleAsync(user.RoleId, cancellationToken);

        // Generate Access and Refresh tokens
        var (accessToken, expiresAtUtc) = _jwtTokenService.GenerateAccessToken(user, user.Role.Name, permissions);
        var refreshToken = _jwtTokenService.GenerateRefreshToken(user.Id, ipAddress);

        await _refreshTokenRepository.AddAsync(refreshToken, cancellationToken);

        // Create active user session
        var session = new UserSession
        {
            UserId = user.Id,
            SessionToken = Guid.NewGuid().ToString("N"),
            DeviceId = request.DeviceId,
            DeviceName = request.DeviceName,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            StartedAtUtc = DateTime.UtcNow,
            LastActivityAtUtc = DateTime.UtcNow,
            ExpiresAtUtc = DateTime.UtcNow.AddDays(7),
            IsRevoked = false
        };
        await _sessionRepository.AddAsync(session, cancellationToken);

        // Audit Log success
        await LogLoginAttemptAsync(user.Id, normalizedInput, true, ipAddress, userAgent, request.DeviceId, null, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var userDto = new UserDto(
            user.Id,
            user.CompanyId,
            user.ShopId,
            user.FullName,
            user.Username,
            user.Email,
            user.MobileNumber,
            user.RoleId,
            user.Role.Name,
            user.Shop?.ShopName,
            user.IsActive,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        var response = new LoginResponseDto(
            accessToken,
            refreshToken.Token,
            expiresAtUtc,
            userDto,
            permissions
        );

        return ApiResponse<LoginResponseDto>.Ok(response, "Login successful");
    }

    public async Task<ApiResponse<LoginResponseDto>> RefreshTokenAsync(
        RefreshTokenRequestDto request, 
        string? ipAddress = null, 
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return ApiResponse<LoginResponseDto>.Fail("Refresh token is required.");
        }

        var tokenRecord = await _refreshTokenRepository.Query()
            .Include(rt => rt.User)
            .ThenInclude(u => u.Role)
            .Include(rt => rt.User)
            .ThenInclude(u => u.Shop)
            .FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken, cancellationToken);

        if (tokenRecord == null || !tokenRecord.IsActive)
        {
            return ApiResponse<LoginResponseDto>.Fail("Invalid or expired refresh token.");
        }

        var user = tokenRecord.User;
        if (!user.IsActive)
        {
            return ApiResponse<LoginResponseDto>.Fail("User account is inactive.");
        }

        // Revoke current token and generate new one (rotation)
        var newRefreshToken = _jwtTokenService.GenerateRefreshToken(user.Id, ipAddress);
        tokenRecord.RevokedAtUtc = DateTime.UtcNow;
        tokenRecord.RevokedByIp = ipAddress;
        tokenRecord.ReplacedByToken = newRefreshToken.Token;

        await _refreshTokenRepository.AddAsync(newRefreshToken, cancellationToken);

        var permissions = await GetPermissionsForRoleAsync(user.RoleId, cancellationToken);
        var (accessToken, expiresAtUtc) = _jwtTokenService.GenerateAccessToken(user, user.Role.Name, permissions);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var userDto = new UserDto(
            user.Id,
            user.CompanyId,
            user.ShopId,
            user.FullName,
            user.Username,
            user.Email,
            user.MobileNumber,
            user.RoleId,
            user.Role.Name,
            user.Shop?.ShopName,
            user.IsActive,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        var response = new LoginResponseDto(
            accessToken,
            newRefreshToken.Token,
            expiresAtUtc,
            userDto,
            permissions
        );

        return ApiResponse<LoginResponseDto>.Ok(response, "Token refreshed successfully");
    }

    public async Task<ApiResponse<bool>> LogoutAsync(
        LogoutRequestDto request, 
        CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            var token = await _refreshTokenRepository.FirstOrDefaultAsync(
                rt => rt.Token == request.RefreshToken, 
                cancellationToken);

            if (token != null && token.RevokedAtUtc == null)
            {
                token.RevokedAtUtc = DateTime.UtcNow;
                _refreshTokenRepository.Update(token);
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }
        }

        return ApiResponse<bool>.Ok(true, "Logged out successfully");
    }

    public async Task<ApiResponse<bool>> ChangePasswordAsync(
        long userId, 
        ChangePasswordDto request, 
        CancellationToken cancellationToken = default)
    {
        var validationResult = await _changePasswordValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user == null)
        {
            return ApiResponse<bool>.Fail("User not found.");
        }

        if (!_passwordHasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
        {
            return ApiResponse<bool>.Fail("Current password does not match.");
        }

        user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword);
        user.UpdatedAtUtc = DateTime.UtcNow;

        _userRepository.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ApiResponse<bool>.Ok(true, "Password changed successfully.");
    }

    public async Task<ApiResponse<bool>> ForgotPasswordAsync(
        ForgotPasswordDto request, 
        CancellationToken cancellationToken = default)
    {
        var validationResult = await _forgotPasswordValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var target = request.UsernameOrEmail.Trim().ToLowerInvariant();
        var user = await _userRepository.FirstOrDefaultAsync(
            u => u.Username.ToLower() == target || (u.Email != null && u.Email.ToLower() == target), 
            cancellationToken);

        // Always return success message for security prevention of user enumeration
        return ApiResponse<bool>.Ok(
            true, 
            "If an account with that username or email exists, reset instructions have been dispatched.");
    }

    private async Task<List<string>> GetPermissionsForRoleAsync(int roleId, CancellationToken cancellationToken)
    {
        var role = await _roleRepository.GetByIdAsync(roleId, cancellationToken);
        if (role == null) return [];

        if (role.Name == "SAdmin")
        {
            // SAdmin has all permissions
            var all = await _permissionRepository.GetAllAsync(cancellationToken);
            return all.Select(p => p.Code).ToList();
        }

        var rolePermissions = await _rolePermissionRepository.Query()
            .Include(rp => rp.Permission)
            .Where(rp => rp.RoleId == roleId)
            .Select(rp => rp.Permission.Code)
            .ToListAsync(cancellationToken);

        return rolePermissions;
    }

    private async Task LogLoginAttemptAsync(
        long? userId, 
        string username, 
        bool isSuccess, 
        string? ipAddress, 
        string? userAgent, 
        string? deviceId, 
        string? failureReason, 
        CancellationToken cancellationToken)
    {
        try
        {
            var log = new LoginAuditLog
            {
                UserId = userId,
                UsernameAttempted = username,
                IsSuccess = isSuccess,
                IpAddress = ipAddress,
                UserAgent = userAgent,
                DeviceId = deviceId,
                FailureReason = failureReason,
                AttemptedAtUtc = DateTime.UtcNow
            };

            await _auditLogRepository.AddAsync(log, cancellationToken);
        }
        catch
        {
            // Logging audit failure should not break auth pipeline
        }
    }
}

