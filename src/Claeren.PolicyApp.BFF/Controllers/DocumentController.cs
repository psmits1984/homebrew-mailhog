using Claeren.PolicyApp.BFF.Mock;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/documents")]
public class DocumentController : ControllerBase
{
    [HttpGet("{documentId}")]
    public IActionResult GetDocument(string documentId)
    {
        var doc = MockData.PolisDetails.Values
            .SelectMany(d => d.Documenten)
            .FirstOrDefault(d => d.DocumentId == documentId);

        if (doc is null) return NotFound();

        var html = "<!DOCTYPE html>" +
            "<html lang='nl'><head>" +
            "<meta charset='UTF-8'>" +
            $"<title>{doc.Naam}</title>" +
            "<style>" +
            "body{font-family:-apple-system,sans-serif;max-width:600px;margin:60px auto;padding:0 24px;color:#1a1a2e}" +
            ".hdr{background:#8B7028;color:white;padding:24px;border-radius:12px;margin-bottom:32px}" +
            "h1{margin:0 0 4px;font-size:20px}" +
            "p{color:rgba(255,255,255,0.8);margin:0;font-size:14px}" +
            ".field{margin:16px 0;padding:12px 16px;background:#f5f0e5;border-radius:8px}" +
            ".lbl{font-size:12px;color:#6b7280;margin-bottom:4px}" +
            ".val{font-weight:600}" +
            ".mock{background:#fff3cd;border:1px solid #ffc107;padding:12px 16px;border-radius:8px;margin-top:24px;font-size:13px}" +
            "</style></head><body>" +
            "<div class='hdr'>" +
            $"<h1>{doc.Naam}</h1>" +
            $"<p>Claeren Verzekeringsportal &mdash; {doc.Type}</p>" +
            "</div>" +
            $"<div class='field'><div class='lbl'>Document ID</div><div class='val'>{doc.DocumentId}</div></div>" +
            $"<div class='field'><div class='lbl'>Type</div><div class='val'>{doc.Type}</div></div>" +
            $"<div class='field'><div class='lbl'>Datum</div><div class='val'>{doc.Datum:dd-MM-yyyy}</div></div>" +
            "<div class='mock'>&#9888; Dit is een <strong>mock document</strong> voor testdoeleinden. " +
            "In productie wordt hier het werkelijke polisblad getoond als PDF.</div>" +
            "</body></html>";

        return Content(html, "text/html");
    }
}
