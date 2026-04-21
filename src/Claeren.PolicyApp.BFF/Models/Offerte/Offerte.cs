namespace Claeren.PolicyApp.BFF.Models.Offerte;

public record Offerte(
    string Id,
    string EntityId,
    string Referentie,
    string Omschrijving,
    RelatieSoort RelatieSoort,
    OfferteStatus Status,
    string ProductType,
    string Dekking,
    decimal JaarPremie,
    DateOnly Ingangsdatum,
    DateOnly GeldigTot,
    DateTime AangemaaktOp,
    string? KvkNummer = null,
    string? ContactpersoonEmail = null
);
