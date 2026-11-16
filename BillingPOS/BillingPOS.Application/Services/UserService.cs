using BillingPOS.Application.DTOs;
using BillingPOS.Application.Exceptions;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Entities;
using BillingPOS.Domain.Interfaces;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using ValidationException = BillingPOS.Application.Exceptions.ValidationException;

namespace BillingPOS.Application.Services;

public class UserService : IUserService
{
    private readonly IRepository<User> _userRepository;
    private readonly IRepository<Role, int> _roleRepository;
    private readonly IRepository<Permission, int> _permissionRepository;
    private readonly IRepository<RolePermission, int> _rolePermissionRepository;
    private readonly IRepository<Company> _companyRepository;
    private readonly IRepository<Shop> _shopRepository;
    private readonly IRepository<LoginAuditLog> _auditLogRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IValidator<CreateUserDto> _createValidator;
    private readonly IValidator<UpdateUserDto> _updateValidator;

    public UserService(
        IRepository<User> userRepository,
        IRepository<Role, int> roleRepository,
        IRepository<Permission, int> permissionRepository,
        IRepository<RolePermission, int> rolePermissionRepository,
        IRepository<Company> companyRepository,
        IRepository<Shop> shopRepository,
        IRepository<LoginAuditLog> auditLogRepository,
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        IValidator<CreateUserDto> createValidator,
        IValidator<UpdateUserDto> updateValidator)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _permissionRepository = permissionRepository;
        _rolePermissionRepository = rolePermissionRepository;
        _companyRepository = companyRepository;
        _shopRepository = shopRepository;
        _auditLogRepository = auditLogRepository;
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    public async Task<ApiResponse<UserDto>> CreateUserAsync(
        CreateUserDto request, 
        CancellationToken cancellationToken = default)
    {
        var validationResult = await _createValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var normalizedUsername = request.Username.Trim().ToLowerInvariant();

        var existingUser = await _userRepository.FirstOrDefaultAsync(
            u => u.Username.ToLower() == normalizedUsername, 
            cancellationToken);

        if (existingUser != null)
        {
            return ApiResponse<UserDto>.Fail(
                "Username already exists.", 
                ["A user with this username is already registered. Please choose another."]);
        }

        var role = await _roleRepository.GetByIdAsync(request.RoleId, cancellationToken);
        if (role == null || !role.IsActive)
        {
            return ApiResponse<UserDto>.Fail("Specified role is invalid or inactive.");
        }

        // Get company and shop
        var company = await _companyRepository.FirstOrDefaultAsync(c => c.IsActive, cancellationToken);
        if (company == null)
        {
            return ApiResponse<UserDto>.Fail("Company must be configured before registering users.");
        }

        long? targetShopId = request.ShopId;
        if (targetShopId == null)
        {
            var shop = await _shopRepository.FirstOrDefaultAsync(s => s.CompanyId == company.Id, cancellationToken);
            targetShopId = shop?.Id;
        }

        var user = new User
        {
            CompanyId = company.Id,
            ShopId = targetShopId,
            FullName = request.FullName.Trim(),
            Username = request.Username.Trim(),
            Email = request.Email?.Trim().ToLowerInvariant(),
            MobileNumber = request.MobileNumber?.Trim(),
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            RoleId = request.RoleId,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        await _userRepository.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Fetch back with navigations
        var shopInfo = targetShopId.HasValue ? await _shopRepository.GetByIdAsync(targetShopId.Value, cancellationToken) : null;

        var dto = new UserDto(
            user.Id,
            user.CompanyId,
            user.ShopId,
            user.FullName,
            user.Username,
            user.Email,
            user.MobileNumber,
            user.RoleId,
            role.Name,
            shopInfo?.ShopName,
            user.IsActive,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        return ApiResponse<UserDto>.Ok(dto, "User created successfully.");
    }

    public async Task<ApiResponse<PagedResult<UserDto>>> GetUsersAsync(
        int pageNumber = 1, 
        int pageSize = 20, 
        string? search = null, 
        int? roleId = null, 
        bool? isActive = null, 
        CancellationToken cancellationToken = default)
    {
        var query = _userRepository.Query()
            .Include(u => u.Role)
            .Include(u => u.Shop)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                u.FullName.ToLower().Contains(term) ||
                u.Username.ToLower().Contains(term) ||
                (u.Email != null && u.Email.ToLower().Contains(term)) ||
                (u.MobileNumber != null && u.MobileNumber.Contains(term)));
        }

        if (roleId.HasValue && roleId.Value > 0)
        {
            query = query.Where(u => u.RoleId == roleId.Value);
        }

        if (isActive.HasValue)
        {
            query = query.Where(u => u.IsActive == isActive.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var users = await query
            .OrderBy(u => u.RoleId)
            .ThenBy(u => u.FullName)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new UserDto(
                u.Id,
                u.CompanyId,
                u.ShopId,
                u.FullName,
                u.Username,
                u.Email,
                u.MobileNumber,
                u.RoleId,
                u.Role.Name,
                u.Shop != null ? u.Shop.ShopName : null,
                u.IsActive,
                u.CreatedAtUtc,
                u.UpdatedAtUtc
            ))
            .ToListAsync(cancellationToken);

        var pagedResult = new PagedResult<UserDto>(users, totalCount, pageNumber, pageSize);

        return ApiResponse<PagedResult<UserDto>>.Ok(pagedResult);
    }

    public async Task<ApiResponse<UserDto>> GetUserByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.Query()
            .Include(u => u.Role)
            .Include(u => u.Shop)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

        if (user == null)
        {
            return ApiResponse<UserDto>.Fail("User not found.");
        }

        var dto = new UserDto(
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

        return ApiResponse<UserDto>.Ok(dto);
    }

    public async Task<ApiResponse<UserDto>> UpdateUserAsync(
        long id, 
        UpdateUserDto request, 
        CancellationToken cancellationToken = default)
    {
        var validationResult = await _updateValidator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            throw new ValidationException(validationResult.Errors.Select(e => e.ErrorMessage));
        }

        var user = await _userRepository.Query()
            .Include(u => u.Role)
            .Include(u => u.Shop)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

        if (user == null)
        {
            return ApiResponse<UserDto>.Fail("User not found.");
        }

        var role = await _roleRepository.GetByIdAsync(request.RoleId, cancellationToken);
        if (role == null || !role.IsActive)
        {
            return ApiResponse<UserDto>.Fail("Specified role is invalid.");
        }

        user.FullName = request.FullName.Trim();
        user.Email = request.Email?.Trim().ToLowerInvariant();
        user.MobileNumber = request.MobileNumber?.Trim();
        user.RoleId = request.RoleId;
        if (request.ShopId.HasValue)
        {
            user.ShopId = request.ShopId;
        }
        user.UpdatedAtUtc = DateTime.UtcNow;

        _userRepository.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var dto = new UserDto(
            user.Id,
            user.CompanyId,
            user.ShopId,
            user.FullName,
            user.Username,
            user.Email,
            user.MobileNumber,
            user.RoleId,
            role.Name,
            user.Shop?.ShopName,
            user.IsActive,
            user.CreatedAtUtc,
            user.UpdatedAtUtc
        );

        return ApiResponse<UserDto>.Ok(dto, "User updated successfully.");
    }

    public async Task<ApiResponse<bool>> UpdateUserStatusAsync(
        long id, 
        bool isActive, 
        CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.Query()
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

        if (user == null)
        {
            return ApiResponse<bool>.Fail("User not found.");
        }

        // Prevent deactivating the last active SAdmin
        if (!isActive && user.Role.Name == "SAdmin")
        {
            var activeSAdminCount = await _userRepository.CountAsync(
                u => u.RoleId == user.RoleId && u.IsActive && u.Id != id, 
                cancellationToken);

            if (activeSAdminCount == 0)
            {
                return ApiResponse<bool>.Fail("Cannot deactivate the only active Super Administrator.");
            }
        }

        user.IsActive = isActive;
        user.UpdatedAtUtc = DateTime.UtcNow;

        _userRepository.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ApiResponse<bool>.Ok(true, $"User status set to {(isActive ? "Active" : "Inactive")}.");
    }

    public async Task<ApiResponse<List<RoleDto>>> GetRolesAsync(CancellationToken cancellationToken = default)
    {
        var roles = await _roleRepository.Query()
            .Include(r => r.RolePermissions)
            .ThenInclude(rp => rp.Permission)
            .ToListAsync(cancellationToken);

        var dtos = roles.Select(r => new RoleDto(
            r.Id,
            r.Name,
            r.Description,
            r.IsActive,
            r.RolePermissions.Select(rp => rp.Permission.Code).ToList()
        )).ToList();

        return ApiResponse<List<RoleDto>>.Ok(dtos);
    }

    public async Task<ApiResponse<List<PermissionDto>>> GetPermissionsAsync(CancellationToken cancellationToken = default)
    {
        var permissions = await _permissionRepository.GetAllAsync(cancellationToken);
        var dtos = permissions.OrderBy(p => p.Category).ThenBy(p => p.Name).Select(p => new PermissionDto(
            p.Id,
            p.Code,
            p.Name,
            p.Category,
            p.Description
        )).ToList();

        return ApiResponse<List<PermissionDto>>.Ok(dtos);
    }

    public async Task<ApiResponse<bool>> UpdateRolePermissionsAsync(
        int roleId, 
        List<int> permissionIds, 
        CancellationToken cancellationToken = default)
    {
        var role = await _roleRepository.GetByIdAsync(roleId, cancellationToken);
        if (role == null)
        {
            return ApiResponse<bool>.Fail("Role not found.");
        }

        var existingRolePermissions = await _rolePermissionRepository.FindAsync(
            rp => rp.RoleId == roleId, 
            cancellationToken);

        _rolePermissionRepository.RemoveRange(existingRolePermissions);

        var newRolePermissions = permissionIds.Select(pId => new RolePermission
        {
            RoleId = roleId,
            PermissionId = pId
        }).ToList();

        await _rolePermissionRepository.AddRangeAsync(newRolePermissions, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ApiResponse<bool>.Ok(true, "Role permissions updated successfully.");
    }

    public async Task<ApiResponse<List<LoginAuditLogDto>>> GetLoginAuditLogsAsync(
        int limit = 100, 
        CancellationToken cancellationToken = default)
    {
        var logs = await _auditLogRepository.Query()
            .OrderByDescending(l => l.AttemptedAtUtc)
            .Take(limit)
            .Select(l => new LoginAuditLogDto(
                l.Id,
                l.UserId,
                l.UsernameAttempted,
                l.IsSuccess,
                l.IpAddress,
                l.DeviceId,
                l.FailureReason,
                l.AttemptedAtUtc
            ))
            .ToListAsync(cancellationToken);

        return ApiResponse<List<LoginAuditLogDto>>.Ok(logs);
    }
}
