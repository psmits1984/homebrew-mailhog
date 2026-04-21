using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Compliance;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/compliance")]
[Authorize]
public class UboController : ControllerBase
{
    // POST /api/compliance/ubo – submit manual UBO/CC form
    [HttpPost("ubo")]
    [ProducesResponseType(typeof(UboFormulier), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    public IActionResult SubmitUboFormulier([FromBody] UboFormulierRequest request)
    {
        if (!UserHeeftToegang(request.EntityId)) return Forbid();

        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == request.OfferteId);
        if (offerte is null)
            return BadRequest(new { message = "Offerte niet gevonden." });

        if (string.IsNullOrWhiteSpace(request.UboNaam))
            return BadRequest(new { message = "UBO naam is verplicht." });

        if (request.UboBelangPercentage is < 0 or > 100)
            return BadRequest(new { message = "Belang percentage moet tussen 0 en 100 liggen." });

        // In production: persist UBO form, trigger compliance review workflow,
        // send notification to compliance officer
        var formulier = new UboFormulier(
            Id: $"UBO-{DateTime.UtcNow:yyyyMMddHHmmss}-{request.OfferteId}",
            OfferteId: request.OfferteId,
            EntityId: request.EntityId,
            UboNaam: request.UboNaam,
            UboGeboortedatum: request.UboGeboortedatum,
            UboNationaliteit: request.UboNationaliteit,
            UboBelangPercentage: request.UboBelangPercentage,
            HerkomstGelden: request.HerkomstGelden,
            BedrijfsActiviteiten: request.BedrijfsActiviteiten,
            KvkUittrekselUrl: request.KvkUittrekselUrl,
            Status: ComplianceStatus.InBehandeling
        );

        return CreatedAtAction(nameof(GetComplianceStatus),
            new { entityId = request.EntityId },
            formulier);
    }

    // GET /api/compliance/{entityId}/status – get compliance status for entity
    [HttpGet("{entityId}/status")]
    [ProducesResponseType(typeof(ComplianceStatusResponse), 200)]
    [ProducesResponseType(403)]
    public IActionResult GetComplianceStatus(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        // In production: query persisted compliance checks from database
        // Mock: return a summary for the entity
        var offertes = MockData.Offertes
            .Where(o => o.EntityId == entityId)
            .ToList();

        var response = new ComplianceStatusResponse(
            EntityId: entityId,
            AantalOffertes: offertes.Count,
            AantalGetekend: offertes.Count(o =>
                o.Status == Models.Offerte.OfferteStatus.Getekend),
            HeeftOpenUboFormulier: false,
            LaatstGecontroleerd: DateTime.UtcNow.AddDays(-7)
        );

        return Ok(response);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }

    public record ComplianceStatusResponse(
        string EntityId,
        int AantalOffertes,
        int AantalGetekend,
        bool HeeftOpenUboFormulier,
        DateTime? LaatstGecontroleerd
    );
}
