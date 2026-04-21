namespace Claeren.PolicyApp.BFF.Models.Policy;

public record Policy(
    string PolisNummer,
    string Omschrijving,
    string Maatschappij,
    PolicyStatus Status,
    decimal JaarPremie,
    DateOnly Ingangsdatum,
    DateOnly Vervaldatum,
    string ProductCode,
    string EntityId,
    bool AutomatischIncasso = false
);

public enum PolicyStatus
{
    Actief,
    Geroyeerd,
    Geschorst,
    InAanvraag
}
