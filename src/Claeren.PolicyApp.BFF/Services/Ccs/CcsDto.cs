namespace Claeren.PolicyApp.BFF.Services.Ccs;

// CCS Level 7 response DTO's — veldnamen volgen de CCS Level 7 REST API conventie.
// Pas deze aan zodra de definitieve CCS API specificatie beschikbaar is.

public record CcsPolisResponse(
    string PolisnummerCcs,
    string OmschrijvingPolis,
    string MaatschappijCode,
    string MaatschappijNaam,
    string StatusCode,
    decimal BrutoJaarpremie,
    string Ingangsdatum,     // "yyyy-MM-dd"
    string Vervaldatum,      // "yyyy-MM-dd"
    string ProductCode,
    string RelatieCcs
);

public record CcsPolisDetailResponse(
    string PolisnummerCcs,
    string OmschrijvingPolis,
    string MaatschappijCode,
    string MaatschappijNaam,
    string StatusCode,
    decimal BrutoJaarpremie,
    decimal EigenRisicoBedrag,
    string Ingangsdatum,
    string Vervaldatum,
    string ProductCode,
    string RelatieCcs,
    List<CcsDekkingDto> Dekkingen,
    List<CcsDocumentDto> Documenten,
    List<CcsHistorieDto> Historieregels
);

public record CcsDekkingDto(
    string DekkingCode,
    string DekkingOmschrijving,
    decimal? VerzekerdBedrag
);

public record CcsDocumentDto(
    string DocumentId,
    string DocumentNaam,
    string DocumentSoort,
    string DatumAanmaak,
    string DownloadUri
);

public record CcsHistorieDto(
    string MutatieDatum,
    string MutatieOmschrijving,
    decimal? PremieOud,
    decimal? PremieNieuw
);

public record CcsSchadeResponse(
    string SchadenummerCcs,
    string PolisnummerCcs,
    string OmschrijvingSchade,
    string StatusCode,
    string SchadeDatum,
    string AanmeldDatum,
    decimal? GereserveerdBedrag,
    decimal? UitgekeerdBedrag
);

public record CcsMeldSchadeRequest(
    string PolisnummerCcs,
    string SchadeDatum,
    string OmschrijvingSchade,
    string? Locatie,
    decimal? GeschatteSchade
);

public record CcsMeldSchadeResponse(bool Geslaagd, string? SchadenummerCcs, string? Foutmelding);

public record CcsNaverrekenUitvraagResponse(
    string UitvraagId,
    string PolisnummerCcs,
    string OmschrijvingUitvraag,
    int ContractJaar,
    string Deadline,
    List<CcsNaverrekenVraagDto> Vragen
);

public record CcsNaverrekenVraagDto(
    string VraagCode,
    string VraagTekst,
    string VraagType,
    bool IsVerplicht,
    List<string>? Keuzeopties
);

public record CcsNaverrekenAntwoordRequest(
    string UitvraagId,
    List<CcsVraagAntwoordDto> Antwoorden
);

public record CcsVraagAntwoordDto(string VraagCode, string AntwoordWaarde);
