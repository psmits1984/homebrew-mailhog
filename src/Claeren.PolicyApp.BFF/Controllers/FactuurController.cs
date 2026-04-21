using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Payment;
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

        string statusLabel;
        string statusColor;
        switch (payment.Status)
        {
            case PaymentStatus.Openstaand:
                statusLabel = "Openstaand";
                statusColor = "#F57C00";
                break;
            case PaymentStatus.Mislukt:
                statusLabel = "Mislukt";
                statusColor = "#D32F2F";
                break;
            default:
                statusLabel = "Betaald";
                statusColor = "#2E7D32";
                break;
        }

        var badgeStyle = $"display:inline-block;padding:3px 10px;border-radius:6px;font-size:12px;font-weight:700;color:{statusColor};background:{statusColor}1a";

        var html = "<!DOCTYPE html>" +
            "<html lang='nl'><head>" +
            "<meta charset='UTF-8'>" +
            "<meta name='viewport' content='width=device-width, initial-scale=1'>" +
            $"<title>Factuur {payment.FactuurNummer}</title>" +
            "<style>" +
            "*{box-sizing:border-box;margin:0;padding:0}" +
            "body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#F5F0E5;min-height:100vh;padding:24px 16px;color:#1a1a2e}" +
            ".card{background:white;border-radius:12px;max-width:560px;margin:0 auto;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.12)}" +
            ".hdr{background:#8B7028;color:white;padding:24px 28px}" +
            ".hdr h1{font-size:18px;font-weight:700;margin-bottom:4px}" +
            ".hdr p{font-size:13px;opacity:.8}" +
            ".bd{padding:24px 28px}" +
            ".row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #E5DEC8}" +
            ".row:last-child{border-bottom:none}" +
            ".lbl{font-size:13px;color:#6B7280;flex:0 0 140px}" +
            ".val{font-size:13px;font-weight:600;text-align:right}" +
            ".amt{font-size:22px;font-weight:800;color:#8B7028;margin:16px 0 4px}" +
            ".hr{border:none;border-top:2px solid #E5DEC8;margin:16px 0}" +
            ".note{background:#fff3cd;border:1px solid #ffc107;border-radius:8px;padding:12px 16px;margin-top:20px;font-size:12px;color:#856404}" +
            "@media print{body{background:white;padding:0}.card{box-shadow:none}}" +
            "</style></head><body>" +
            "<div class='card'>" +
            "<div class='hdr'>" +
            $"<h1>Factuur {payment.FactuurNummer}</h1>" +
            "<p>Claeren Verzekeringsportal &bull; Betaalbewijs</p>" +
            "</div>" +
            "<div class='bd'>" +
            $"<div class='amt'>&euro; {payment.Bedrag:N2}</div>" +
            $"<div style='margin-bottom:16px'><span style='{badgeStyle}'>{statusLabel}</span></div>" +
            "<hr class='hr'>" +
            "<div class='row'>" +
            $"<span class='lbl'>Factuurnummer</span><span class='val'>{payment.FactuurNummer}</span>" +
            "</div>" +
            "<div class='row'>" +
            $"<span class='lbl'>Datum</span><span class='val'>{payment.Datum:dd-MM-yyyy}</span>" +
            "</div>" +
            "<div class='row'>" +
            $"<span class='lbl'>Polis</span><span class='val'>{payment.PolisNummer}</span>" +
            "</div>" +
            "<div class='row'>" +
            $"<span class='lbl'>Omschrijving</span><span class='val'>{payment.OmschrijvingPolis}</span>" +
            "</div>" +
            "<div class='row'>" +
            $"<span class='lbl'>Bedrag</span><span class='val'>&euro; {payment.Bedrag:N2}</span>" +
            "</div>" +
            "<div class='note'>&#9888; Dit is een <strong>mock factuur</strong> voor testdoeleinden. " +
            "In productie wordt hier de werkelijke factuur als PDF getoond.</div>" +
            "</div>" +
            "</div>" +
            "</body></html>";

        return Content(html, "text/html");
    }
}
