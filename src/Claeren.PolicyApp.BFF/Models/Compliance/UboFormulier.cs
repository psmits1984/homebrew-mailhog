namespace Claeren.PolicyApp.BFF.Models.Compliance;

public record UboFormulier(
    string Id,
    string OfferteId,
    string EntityId,
    string UboNaam,
    DateOnly UboGeboortedatum,
    string UboNationaliteit,
    decimal UboBelangPercentage,
    string HerkomstGelden,
    string BedrijfsActiviteiten,
    string? KvkUittrekselUrl,
    ComplianceStatus Status
);

public record UboFormulierRequest(
    string OfferteId,
    string EntityId,
    string UboNaam,
    DateOnly UboGeboortedatum,
    string UboNationaliteit,
    decimal UboBelangPercentage,
    string HerkomstGelden,
    string BedrijfsActiviteiten,
    string? KvkUittrekselUrl = null
);
