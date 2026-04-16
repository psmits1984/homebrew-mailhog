using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/entiteiten/{entityId}/claims")]
[Authorize]
public class ClaimController(ICcsService ccsService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<Claim>), 200)]
    [ProducesResponseType(403)]
    public async Task<IActionResult> GetClaims(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var claims = await ccsService.GetClaimsAsync(entityId);
        return Ok(claims);
    }

    [HttpPost]
    [ProducesResponseType(typeof(ClaimResponse), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    public async Task<IActionResult> MeldClaim(string entityId, [FromBody] ClaimRequest request)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var result = await ccsService.MeldClaimAsync(request, entityId);
        if (!result.Success)
            return BadRequest(new { message = result.ErrorMessage });

        return StatusCode(201, result);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
