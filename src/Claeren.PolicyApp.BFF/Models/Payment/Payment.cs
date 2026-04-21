namespace Claeren.PolicyApp.BFF.Models.Payment;

public record Payment(
    string Id,
    string EntityId,
    string PolisNummer,
    string OmschrijvingPolis,
    DateTime Datum,
    decimal Bedrag,
    PaymentStatus Status,
    string FactuurNummer,
    string FactuurDownloadUrl
);

public enum PaymentStatus { Betaald, Openstaand, Mislukt }
