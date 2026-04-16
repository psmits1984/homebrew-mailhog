using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/entiteiten/{entityId}/naverrrekening")]
[Authorize]
public class NaverrekenController(ICcsService ccsService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<NaverrekenUitvraag>), 200)]
    [ProducesResponseType(403)]
    public async Task<IActionResult> GetUitvragen(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var uitvragen = await ccsService.GetNaverrekenUitvragenAsync(entityId);
        return Ok(uitvragen);
    }

    [HttpPost("{uitvraagId}/antwoorden")]
    [ProducesResponseType(204)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    public async Task<IActionResult> BeantwoordUitvraag(
        string entityId, string uitvraagId, [FromBody] NaverrekenAntwoord antwoord)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();
        if (antwoord.UitvraagId != uitvraagId) return BadRequest();

        var success = await ccsService.BeantwoordNaverrekenUitvraagAsync(antwoord, entityId);
        return success ? NoContent() : BadRequest();
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
