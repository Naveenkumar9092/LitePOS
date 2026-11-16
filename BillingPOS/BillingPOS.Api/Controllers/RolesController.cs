using Asp.Versioning;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/roles")]
[Authorize]
public class RolesController : BaseApiController
{
    private readonly IUserService _userService;

    public RolesController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    [Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
    [ProducesResponseType(typeof(ApiResponse<List<RoleDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRoles(CancellationToken cancellationToken)
    {
        var result = await _userService.GetRolesAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:int}/permissions")]
    [Authorize(Roles = RoleConstants.SAdmin)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateRolePermissions(int id, [FromBody] UpdateRolePermissionsDto request, CancellationToken cancellationToken)
    {
        var result = await _userService.UpdateRolePermissionsAsync(id, request.PermissionIds, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }
}

