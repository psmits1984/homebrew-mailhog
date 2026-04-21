public record MachtigingResponse(
    string MandaatReferentie,
    string MandaatType,
    string Iban,
    string? PolisNummer,
    DateTime Tijdstempel,
    string IpAdres,
    string BevestigingsEmail
);
