using Claeren.PolicyApp.BFF.Models.Policy;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/entiteiten/{entityId}/polissen")]
[Authorize]
public class PolicyController(ICcsService ccsService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<Policy>), 200)]
    [ProducesResponseType(403)]
    public async Task<IActionResult> GetPolissen(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var polissen = await ccsService.GetPolissenAsync(entityId);
        return Ok(polissen);
    }

    [HttpGet("{polisNummer}")]
    [ProducesResponseType(typeof(PolicyDetail), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetPolisDetail(string entityId, string polisNummer)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var detail = await ccsService.GetPolisDetailAsync(polisNummer, entityId);
        if (detail is null) return NotFound();

        return Ok(detail);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
