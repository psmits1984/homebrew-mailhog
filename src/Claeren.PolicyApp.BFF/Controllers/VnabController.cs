using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Compliance;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

/*
 * VNAB Sanctie Platform SOAP integration
 *
 * Production endpoint : https://webservices.sanctieplatform.nl/
 * Test endpoint       : https://wit-webservices.sanctieplatform.nl/
 *
 * Key SOAP operations (from WSDL):
 *   SearchPersonsByCriteria  – zoek personen op naam + geboortedatum
 *   GetOrganisationsByKvKNumber – zoek organisaties op KvK-nummer
 *   CreateInvestigation      – start een officieel onderzoek (PEP/sancties)
 *
 * WSDL request skeleton (SearchPersonsByCriteria):
 *   <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
 *                     xmlns:sp="http://sanctieplatform.vnab.nl/ws">
 *     <soapenv:Header>
 *       <sp:Authentication>
 *         <sp:Username>{username}</sp:Username>
 *         <sp:Password>{password}</sp:Password>
 *       </sp:Authentication>
 *     </soapenv:Header>
 *     <soapenv:Body>
 *       <sp:SearchPersonsByCriteria>
 *         <sp:FirstName>{firstName}</sp:FirstName>
 *         <sp:LastName>{lastName}</sp:LastName>
 *         <sp:DateOfBirth>{yyyy-MM-dd}</sp:DateOfBirth>
 *         <sp:Nationality>{NL}</sp:Nationality>
 *       </sp:SearchPersonsByCriteria>
 *     </soapenv:Body>
 *   </soapenv:Envelope>
 *
 * Response contains: <MatchResult>Clear|PossibleHit</MatchResult>
 *   + <RiskIndicators> list with type (Sanction/PEP/AML) and source (EU/UN/OFAC/NL)
 *
 * Real implementation:
 *   - Inject IHttpClientFactory, create named client "vnab"
 *   - POST SOAP XML with Content-Type: text/xml; charset=utf-8
 *   - SOAPAction header: "http://sanctieplatform.vnab.nl/ws/SearchPersonsByCriteria"
 *   - Parse XML response with XDocument or generated WSDL proxy (dotnet-svcutil)
 *   - Map "PossibleHit" → ComplianceStatus.HandmatigVereist
 *   - Map "Clear"       → ComplianceStatus.Goedgekeurd
 */

[ApiController]
[Route("api/compliance")]
[Authorize]
public class VnabController : ControllerBase
{
    private static readonly Random _rng = new();

    public record ComplianceCheckRequest(
        string EntityId,
        string OfferteId,
        string RelatieSoort,
        string? KvkNummer = null,
        string? Naam = null,
        DateOnly? Geboortedatum = null,
        string? Nationaliteit = null
    );

    // POST /api/compliance/check
    [HttpPost("check")]
    [ProducesResponseType(typeof(ComplianceCheck), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    public IActionResult TriggerCheck([FromBody] ComplianceCheckRequest request)
    {
        if (!UserHeeftToegang(request.EntityId)) return Forbid();

        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == request.OfferteId);
        if (offerte is null) return BadRequest(new { message = "Offerte niet gevonden." });

        // Mock: 70% Goedgekeurd, 30% HandmatigVereist
        // In production: call VNAB SOAP API (see comment above)
        var isGoedgekeurd = _rng.NextDouble() < 0.70;

        var check = new ComplianceCheck(
            Id: $"CC-{DateTime.UtcNow:yyyyMMddHHmmss}-{request.OfferteId}",
            EntityId: request.EntityId,
            OfferteId: request.OfferteId,
            RelatieSoort: request.RelatieSoort,
            Status: isGoedgekeurd ? ComplianceStatus.Goedgekeurd : ComplianceStatus.HandmatigVereist,
            VnabReferentie: isGoedgekeurd ? $"VNAB-{Guid.NewGuid():N[..8]}" : null,
            Tijdstempel: DateTime.UtcNow,
            Bevindingen: isGoedgekeurd
                ? "Geen hits gevonden in EU-, VN- en OFAC-sanctielijsten. PEP-screening negatief."
                : "Mogelijke overeenkomst gevonden. Handmatige beoordeling UBO/CC-formulier vereist."
        );

        // In production: persist check result and link to offerte/entity
        return Ok(check);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
