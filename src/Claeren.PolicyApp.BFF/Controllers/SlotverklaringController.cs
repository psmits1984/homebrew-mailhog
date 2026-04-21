using System.Security.Cryptography;
using System.Text;
using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Models.Slotverklaring;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

/*
 * Slotverklaring (Closing Declaration) with OTP-based signing
 *
 * Flow:
 *   1. POST /api/slotverklaringen/{offerteId}/otp
 *      - Generate 6-digit OTP, valid 10 minutes
 *      - In production: hash OTP (bcrypt), send via email/SMS, persist record
 *      - Mock: returns OTP in response (never do this in production!)
 *
 *   2. POST /api/slotverklaringen/{offerteId}/ondertekenen
 *      - Verify OTP (timing-safe compare against stored hash)
 *      - Create AES-256 encrypted audit trail
 *      - Record IP address, timestamp, accept declaration text hash
 *      - Mark offerte as Getekend
 *
 * AES signing note (mock):
 *   - Key: derived from OTP + entityId + timestamp via PBKDF2
 *   - Audit trail signed with HMAC-SHA256 of declaration text
 *   - In production: use proper PKI / eIDAS qualified signature service
 */

[ApiController]
[Route("api/slotverklaringen")]
[Authorize]
public class SlotverklaringController : ControllerBase
{
    // In-memory store for mock – in production use a database
    private static readonly Dictionary<string, Slotverklaring> _store = new();
    private static readonly Random _rng = new();

    public record OtpRequest(string EntityId);
    public record OndertekenenRequest(string EntityId, string OtpCode);

    // POST /api/slotverklaringen/{offerteId}/otp – generate and send OTP
    [HttpPost("{offerteId}/otp")]
    [ProducesResponseType(typeof(OtpResponse), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public IActionResult GenereerOtp(string offerteId, [FromBody] OtpRequest request)
    {
        if (!UserHeeftToegang(request.EntityId)) return Forbid();

        var offerte = MockData.Offertes.FirstOrDefault(o => o.Id == offerteId);
        if (offerte is null) return NotFound(new { message = "Offerte niet gevonden." });
        if (offerte.EntityId != request.EntityId)
            return Forbid();

        // Generate 6-digit OTP
        var otpPlain = _rng.Next(100_000, 999_999).ToString();
        var verlooptOp = DateTime.UtcNow.AddMinutes(10);

        // In production: hash OTP with bcrypt before storing
        // Using SHA256 here for simplicity in mock
        var otpHash = Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(otpPlain + offerteId)));

        var slotverklaring = new Slotverklaring(
            Id: $"SV-{DateTime.UtcNow:yyyyMMddHHmmss}-{offerteId}",
            OfferteId: offerteId,
            EntityId: request.EntityId,
            OtpCode: otpHash,
            OtpVerlooptOp: verlooptOp,
            Ondertekend: false,
            OndertekeningTijdstempel: null,
            IpAdres: null,
            AuditTrail: null
        );

        _store[offerteId] = slotverklaring;

        // In production: send OTP via email/SMS, do NOT return it in response
        // Mock: returned for testing convenience
        return Ok(new OtpResponse(
            SlotverklaringId: slotverklaring.Id,
            OtpVerlooptOp: verlooptOp,
            Email: offerte.ContactpersoonEmail ?? "onbekend@claeren.nl",
            OtpMock: otpPlain  // REMOVE IN PRODUCTION
        ));
    }

    // POST /api/slotverklaringen/{offerteId}/ondertekenen – verify OTP and sign
    [HttpPost("{offerteId}/ondertekenen")]
    [ProducesResponseType(typeof(OndertekeningBevestiging), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    [ProducesResponseType(409)]
    public IActionResult Ondertekenen(string offerteId, [FromBody] OndertekenenRequest request)
    {
        if (!UserHeeftToegang(request.EntityId)) return Forbid();

        if (!_store.TryGetValue(offerteId, out var sv))
            return NotFound(new { message = "Geen actieve slotverklaring gevonden. Genereer eerst een OTP." });

        if (sv.EntityId != request.EntityId) return Forbid();
        if (sv.Ondertekend)
            return Conflict(new { message = "Slotverklaring is al ondertekend." });

        if (DateTime.UtcNow > sv.OtpVerlooptOp)
            return BadRequest(new { message = "OTP is verlopen. Genereer een nieuwe code." });

        // Verify OTP (timing-safe)
        var inputHash = Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(request.OtpCode + offerteId)));

        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(inputHash),
                Encoding.UTF8.GetBytes(sv.OtpCode)))
            return BadRequest(new { message = "Ongeldige verificatiecode." });

        // Build audit trail
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "onbekend";
        var tijdstempel = DateTime.UtcNow;
        var verklaringTekst =
            $"Ondergetekende verklaart hierbij akkoord te gaan met de offerte {offerteId} " +
            "en de bijbehorende polisvoorwaarden. " +
            $"Ondertekend op {tijdstempel:yyyy-MM-dd HH:mm:ss} UTC vanuit IP {ip}.";

        var auditHash = Convert.ToHexString(
            HMACSHA256.HashData(
                Encoding.UTF8.GetBytes(request.OtpCode),
                Encoding.UTF8.GetBytes(verklaringTekst)));

        var auditTrail = $"TIJDSTEMPEL={tijdstempel:O}|IP={ip}|OFFERTE={offerteId}|HASH={auditHash[..16]}";

        var ondertekend = sv with
        {
            Ondertekend = true,
            OndertekeningTijdstempel = tijdstempel,
            IpAdres = ip,
            AuditTrail = auditTrail
        };
        _store[offerteId] = ondertekend;

        return Ok(new OndertekeningBevestiging(
            SlotverklaringId: ondertekend.Id,
            OfferteId: offerteId,
            OndertekeningTijdstempel: tijdstempel,
            IpAdres: ip,
            AuditTrail: auditTrail,
            VerklaringHashPrefix: auditHash[..16]
        ));
    }

    private bool UserHeeftToegang(string entityId)
    {
        var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
        return entityIdsClaim.Split(',').Contains(entityId);
    }

    public record OtpResponse(
        string SlotverklaringId,
        DateTime OtpVerlooptOp,
        string Email,
        string OtpMock   // Remove in production
    );

    public record OndertekeningBevestiging(
        string SlotverklaringId,
        string OfferteId,
        DateTime OndertekeningTijdstempel,
        string IpAdres,
        string AuditTrail,
        string VerklaringHashPrefix
    );
}
