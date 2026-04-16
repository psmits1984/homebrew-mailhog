namespace Claeren.PolicyApp.BFF.Models.Claim;

public record Claim(
    string SchadeNummer,
    string PolisNummer,
    string Omschrijving,
    ClaimStatus Status,
    DateTime SchadeDatum,
    DateTime MeldDatum,
    decimal? GereserveerdBedrag,
    decimal? UitgekeerdBedrag
);

public enum ClaimStatus
{
    InBehandeling,
    Afgehandeld,
    Afgewezen,
    Ingediend
}
