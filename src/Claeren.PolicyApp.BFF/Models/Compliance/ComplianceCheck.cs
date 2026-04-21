namespace Claeren.PolicyApp.BFF.Models.Compliance;

public enum ComplianceStatus
{
    Goedgekeurd,
    Afgewezen,
    HandmatigVereist,
    InBehandeling
}

public record ComplianceCheck(
    string Id,
    string EntityId,
    string OfferteId,
    string RelatieSoort,
    ComplianceStatus Status,
    string? VnabReferentie,
    DateTime Tijdstempel,
    string? Bevindingen
);
