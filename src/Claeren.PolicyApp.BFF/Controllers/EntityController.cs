using System.Security.Claims;
using Claeren.PolicyApp.BFF.Models.Entity;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/entiteiten")]
[Authorize]
public class EntityController(IAuthService authService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<Entity>), 200)]
    public async Task<IActionResult> GetEntiteiten()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var entiteiten = await authService.GetEntiteitenAsync(userId);
        return Ok(entiteiten);
    }
}
