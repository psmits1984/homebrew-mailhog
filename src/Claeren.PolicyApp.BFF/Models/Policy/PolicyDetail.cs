namespace Claeren.PolicyApp.BFF.Models.Policy;

public record PolicyDetail(
    string PolisNummer,
    string Omschrijving,
    string Maatschappij,
    PolicyStatus Status,
    decimal JaarPremie,
    decimal EigenRisico,
    DateOnly Ingangsdatum,
    DateOnly Vervaldatum,
    string ProductCode,
    string EntityId,
    List<Dekking> Dekkingen,
    List<PolisDocument> Documenten,
    List<PolisHistorie> Historie
);

public record Dekking(string Code, string Omschrijving, decimal? Bedrag);

public record PolisDocument(
    string DocumentId,
    string Naam,
    string Type,
    DateTime Datum,
    string DownloadUrl
);

public record PolisHistorie(
    DateTime Datum,
    string Omschrijving,
    decimal? OudePremie,
    decimal? NieuwePremie
);
