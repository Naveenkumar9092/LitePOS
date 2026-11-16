using BillingPOS.Application.DTOs;

namespace BillingPOS.Application.Interfaces;

public interface IUserService
{
    Task<ApiResponse<UserDto>> CreateUserAsync(
        CreateUserDto request, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<PagedResult<UserDto>>> GetUsersAsync(
        int pageNumber = 1, 
        int pageSize = 20, 
        string? search = null, 
        int? roleId = null, 
        bool? isActive = null, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<UserDto>> GetUserByIdAsync(
        long id, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<UserDto>> UpdateUserAsync(
        long id, 
        UpdateUserDto request, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<bool>> UpdateUserStatusAsync(
        long id, 
        bool isActive, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<List<RoleDto>>> GetRolesAsync(
        CancellationToken cancellationToken = default);

    Task<ApiResponse<List<PermissionDto>>> GetPermissionsAsync(
        CancellationToken cancellationToken = default);

    Task<ApiResponse<bool>> UpdateRolePermissionsAsync(
        int roleId, 
        List<int> permissionIds, 
        CancellationToken cancellationToken = default);

    Task<ApiResponse<List<LoginAuditLogDto>>> GetLoginAuditLogsAsync(
        int limit = 100, 
        CancellationToken cancellationToken = default);
}

