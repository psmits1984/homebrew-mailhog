using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Offerte;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Authorize]
public class OfferteController : ControllerBase
{
    // GET /api/entiteiten/{entityId}/offertes
    [HttpGet("api/entiteiten/{entityId}/offertes")]
    [ProducesResponseType(typeof(List<Offerte>), 200)]
    [ProducesResponseType(403)]
    public IActionResult GetOffertes(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var offertes = MockData.Offertes
            .Where(o => o.EntityId == entityId)
            .OrderByDescending(o => o.AangemaaktOp)
            .ToList();

        return Ok(offertes);
    }

    // GET /api/offertes/{id}
    [HttpGet("api/offertes/{id}")]
    [ProducesResponseType(typeof(Offerte), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public IActionResult GetOfferte(string id)
    {
        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == id);
        if (offerte is null) return NotFound();
        if (!UserHeeftToegang(offerte.EntityId)) return Forbid();

        return Ok(offerte);
    }

    // POST /api/offertes/{id}/accorderen
    [HttpPost("api/offertes/{id}/accorderen")]
    [ProducesResponseType(typeof(Offerte), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    [ProducesResponseType(409)]
    public IActionResult Accorderen(string id)
    {
        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == id);
        if (offerte is null) return NotFound();
        if (!UserHeeftToegang(offerte.EntityId)) return Forbid();

        if (offerte.Status != OfferteStatus.Verzonden)
            return Conflict(new { message = "Offerte kan alleen worden geaccordeerd vanuit status Verzonden." });

        // In production: persist status update in database
        var bijgewerkt = offerte with { Status = OfferteStatus.Geaccordeerd };
        return Ok(bijgewerkt);
    }

    // POST /api/offertes/{id}/weigeren
    [HttpPost("api/offertes/{id}/weigeren")]
    [ProducesResponseType(typeof(Offerte), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    [ProducesResponseType(409)]
    public IActionResult Weigeren(string id)
    {
        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == id);
        if (offerte is null) return NotFound();
        if (!UserHeeftToegang(offerte.EntityId)) return Forbid();

        if (offerte.Status != OfferteStatus.Verzonden)
            return Conflict(new { message = "Offerte kan alleen worden geweigerd vanuit status Verzonden." });

        var bijgewerkt = offerte with { Status = OfferteStatus.Geweigerd };
        return Ok(bijgewerkt);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
