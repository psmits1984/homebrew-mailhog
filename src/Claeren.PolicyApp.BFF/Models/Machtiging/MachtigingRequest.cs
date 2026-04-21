public record MachtigingRequest(
    string EntityId,
    string? PolisNummer,
    string Iban,
    string NaamRekeninghouder,
    string Email,
    string MandaatType,
    string MandaatReferentie
);
