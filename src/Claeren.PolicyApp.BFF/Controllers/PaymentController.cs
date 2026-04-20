using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Payment;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/entiteiten/{entityId}/betalingen")]
[Authorize]
public class PaymentController : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<Payment>), 200)]
    [ProducesResponseType(403)]
    public IActionResult GetBetalingen(string entityId)
    {
        if (!UserHeeftToegang(entityId)) return Forbid();

        var betalingen = MockData.Betalingen
            .Where(p => p.EntityId == entityId)
            .OrderByDescending(p => p.Datum)
            .ToList();

        return Ok(betalingen);
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }
}
