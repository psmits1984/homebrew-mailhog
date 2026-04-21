using Claeren.PolicyApp.BFF.Mock;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/facturen")]
public class FactuurController : ControllerBase
{
    [HttpGet("{paymentId}")]
    public IActionResult GetFactuur(string paymentId)
    {
        var payment = MockData.Betalingen.FirstOrDefault(p => p.Id == paymentId);
        if (payment is null) return NotFound();

        var statusLabel = payment.Status switch
        {
            var s when s.ToString() == "Betaald"    => "Betaald",
            var s when s.ToString() == "Openstaand" => "Openstaand",
            _                                       => "Mislukt"
        };

        var statusColor = payment.Status.ToString() switch
        {
            "Betaald"    => "#2E7D32",
            "Openstaand" => "#F57C00",
            _            => "#D32F2F"
        };

        var html = $"""
            <!DOCTYPE html>
            <html lang="nl">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Factuur {payment.FactuurNummer}</title>
              <style>
                * {{ box-sizing: border-box; margin: 0; padding: 0; }}
                body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        background: #F5F0E5; min-height: 100vh; padding: 24px 16px; color: #1a1a2e; }}
                .card {{ background: white; border-radius: 12px; max-width: 560px;
                         margin: 0 auto; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.12); }}
                .header {{ background: #8B7028; color: white; padding: 24px 28px; }}
                .header h1 {{ font-size: 18px; font-weight: 700; margin-bottom: 4px; }}
                .header p {{ font-size: 13px; opacity: 0.8; }}
                .body {{ padding: 24px 28px; }}
                .row {{ display: flex; justify-content: space-between; align-items: flex-start;
                        padding: 10px 0; border-bottom: 1px solid #E5DEC8; }}
                .row:last-child {{ border-bottom: none; }}
                .label {{ font-size: 13px; color: #6B7280; flex: 0 0 140px; }}
                .value {{ font-size: 13px; font-weight: 600; text-align: right; }}
                .status-badge {{ display: inline-block; padding: 3px 10px; border-radius: 6px;
                                 font-size: 12px; font-weight: 700;
                                 color: {statusColor}; background: {statusColor}1a; }}
                .amount {{ font-size: 22px; font-weight: 800; color: #8B7028; margin: 16px 0 4px; }}
                .divider {{ border: none; border-top: 2px solid #E5DEC8; margin: 16px 0; }}
                .mock-note {{ background: #fff3cd; border: 1px solid #ffc107; border-radius: 8px;
                              padding: 12px 16px; margin-top: 20px; font-size: 12px;
                              color: #856404; }}
                @media print {{ body {{ background: white; padding: 0; }}
                                .card {{ box-shadow: none; }} }}
              </style>
            </head>
            <body>
              <div class="card">
                <div class="header">
                  <h1>Factuur {payment.FactuurNummer}</h1>
                  <p>Claeren Verzekeringsportal &bull; Betaalbewijs</p>
                </div>
                <div class="body">
                  <div class="amount">&euro; {payment.Bedrag:N2}</div>
                  <div style="margin-bottom:16px">
                    <span class="status-badge">{statusLabel}</span>
                  </div>
                  <hr class="divider">
                  <div class="row">
                    <span class="label">Factuurnummer</span>
                    <span class="value">{payment.FactuurNummer}</span>
                  </div>
                  <div class="row">
                    <span class="label">Datum</span>
                    <span class="value">{payment.Datum:dd-MM-yyyy}</span>
                  </div>
                  <div class="row">
                    <span class="label">Polis</span>
                    <span class="value">{payment.PolisNummer}</span>
                  </div>
                  <div class="row">
                    <span class="label">Omschrijving</span>
                    <span class="value">{payment.OmschrijvingPolis}</span>
                  </div>
                  <div class="row">
                    <span class="label">Bedrag</span>
                    <span class="value">&euro; {payment.Bedrag:N2}</span>
                  </div>
                  <div class="mock-note">
                    &#9888; Dit is een <strong>mock factuur</strong> voor testdoeleinden.
                    In productie wordt hier de werkelijke factuur als PDF getoond.
                  </div>
                </div>
              </div>
            </body>
            </html>
            """;

        return Content(html, "text/html");
    }
}
