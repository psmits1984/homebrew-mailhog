namespace Claeren.PolicyApp.BFF.Models.Slotverklaring;

public record Slotverklaring(
    string Id,
    string OfferteId,
    string EntityId,
    string OtpCode,           // Stored hashed in production (bcrypt)
    DateTime OtpVerlooptOp,
    bool Ondertekend,
    DateTime? OndertekeningTijdstempel,
    string? IpAdres,
    string? AuditTrail
);
