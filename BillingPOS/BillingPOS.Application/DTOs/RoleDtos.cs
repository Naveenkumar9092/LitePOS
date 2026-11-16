namespace BillingPOS.Application.DTOs;

public record RoleDto(
    int Id,
    string Name,
    string? Description,
    bool IsActive,
    List<string> Permissions
);

public record PermissionDto(
    int Id,
    string Code,
    string Name,
    string Category,
    string? Description
);

public record UpdateRolePermissionsDto(
    List<int> PermissionIds
);

