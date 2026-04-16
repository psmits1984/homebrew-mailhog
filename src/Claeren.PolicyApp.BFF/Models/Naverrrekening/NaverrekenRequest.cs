namespace Claeren.PolicyApp.BFF.Models.Naverrrekening;

public record NaverrekenUitvraag(
    string UitvraagId,
    string PolisNummer,
    string Omschrijving,
    int Jaar,
    DateTime Deadline,
    List<NaverrekenVraag> Vragen
);

public record NaverrekenVraag(
    string VraagId,
    string Vraag,
    string Type,       // "text" | "number" | "date" | "select"
    bool Verplicht,
    List<string>? Opties
);

public record NaverrekenAntwoord(
    string UitvraagId,
    List<VraagAntwoord> Antwoorden
);

public record VraagAntwoord(string VraagId, string Waarde);
