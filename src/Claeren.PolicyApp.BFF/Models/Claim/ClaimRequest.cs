namespace Claeren.PolicyApp.BFF.Models.Claim;

public record ClaimRequest(
    string PolisNummer,
    DateTime SchadeDatum,
    string Omschrijving,
    string? Locatie,
    decimal? GeschadeSchadeEstimatie
);

public record ClaimResponse(
    bool Success,
    string? SchadeNummer,
    string? ErrorMessage
);
