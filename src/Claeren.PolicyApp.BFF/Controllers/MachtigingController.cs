using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/machtigingen")]
[Authorize]
public class MachtigingController : ControllerBase
{
    [HttpPost]
    public IActionResult AfgevenMachtiging([FromBody] MachtigingRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?
            .MapToIPv4().ToString() ?? "onbekend";

        // In productie: stuur bevestigingsmail via SMTP/SendGrid en persisteer audittrail in database.
        var response = new MachtigingResponse(
            MandaatReferentie: request.MandaatReferentie,
            MandaatType:       request.MandaatType,
            Iban:              request.Iban,
            PolisNummer:       request.PolisNummer,
            Tijdstempel:       DateTime.UtcNow,
            IpAdres:           ip,
            BevestigingsEmail: request.Email
        );

        return Ok(response);
    }
}
