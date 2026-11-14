using Asp.Versioning;
using BillingPOS.Application.DTOs;
using BillingPOS.Application.Interfaces;
using BillingPOS.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BillingPOS.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/permissions")]
[Authorize(Roles = $"{RoleConstants.SAdmin},{RoleConstants.Admin}")]
public class PermissionsController : BaseApiController
{
    private readonly IUserService _userService;

    public PermissionsController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<PermissionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPermissions(CancellationToken cancellationToken)
    {
        var result = await _userService.GetPermissionsAsync(cancellationToken);
        return Ok(result);
    }
}

