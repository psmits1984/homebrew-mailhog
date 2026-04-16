using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Policy;

namespace Claeren.PolicyApp.BFF.Services.Ccs;

// Vertaalt CCS Level 7 responses naar BFF-modellen.
// Centraliseer alle veldmapping hier zodat CCS-wijzigingen één plek raken.
public static class CcsMapper
{
    public static Policy ToPolicy(CcsPolisResponse ccs, string entityId) => new(
        PolisNummer: ccs.PolisnummerCcs,
        Omschrijving: ccs.OmschrijvingPolis,
        Maatschappij: ccs.MaatschappijNaam,
        Status: MapStatus(ccs.StatusCode),
        JaarPremie: ccs.BrutoJaarpremie,
        Ingangsdatum: DateOnly.Parse(ccs.Ingangsdatum),
        Vervaldatum: DateOnly.Parse(ccs.Vervaldatum),
        ProductCode: ccs.ProductCode,
        EntityId: entityId
    );

    public static PolicyDetail ToPolisDetail(CcsPolisDetailResponse ccs, string entityId) => new(
        PolisNummer: ccs.PolisnummerCcs,
        Omschrijving: ccs.OmschrijvingPolis,
        Maatschappij: ccs.MaatschappijNaam,
        Status: MapStatus(ccs.StatusCode),
        JaarPremie: ccs.BrutoJaarpremie,
        EigenRisico: ccs.EigenRisicoBedrag,
        Ingangsdatum: DateOnly.Parse(ccs.Ingangsdatum),
        Vervaldatum: DateOnly.Parse(ccs.Vervaldatum),
        ProductCode: ccs.ProductCode,
        EntityId: entityId,
        Dekkingen: ccs.Dekkingen.Select(d => new Dekking(d.DekkingCode, d.DekkingOmschrijving, d.VerzekerdBedrag)).ToList(),
        Documenten: ccs.Documenten.Select(d => new PolisDocument(
            d.DocumentId, d.DocumentNaam, d.DocumentSoort,
            DateTime.Parse(d.DatumAanmaak), d.DownloadUri)).ToList(),
        Historie: ccs.Historieregels.Select(h => new PolisHistorie(
            DateTime.Parse(h.MutatieDatum), h.MutatieOmschrijving,
            h.PremieOud, h.PremieNieuw)).ToList()
    );

    public static Claim ToClaim(CcsSchadeResponse ccs) => new(
        SchadeNummer: ccs.SchadenummerCcs,
        PolisNummer: ccs.PolisnummerCcs,
        Omschrijving: ccs.OmschrijvingSchade,
        Status: MapClaimStatus(ccs.StatusCode),
        SchadeDatum: DateTime.Parse(ccs.SchadeDatum),
        MeldDatum: DateTime.Parse(ccs.AanmeldDatum),
        GereserveerdBedrag: ccs.GereserveerdBedrag,
        UitgekeerdBedrag: ccs.UitgekeerdBedrag
    );

    public static NaverrekenUitvraag ToUitvraag(CcsNaverrekenUitvraagResponse ccs) => new(
        UitvraagId: ccs.UitvraagId,
        PolisNummer: ccs.PolisnummerCcs,
        Omschrijving: ccs.OmschrijvingUitvraag,
        Jaar: ccs.ContractJaar,
        Deadline: DateTime.Parse(ccs.Deadline),
        Vragen: ccs.Vragen.Select(v => new NaverrekenVraag(
            v.VraagCode, v.VraagTekst, v.VraagType, v.IsVerplicht, v.Keuzeopties)).ToList()
    );

    private static PolicyStatus MapStatus(string code) => code.ToUpperInvariant() switch
    {
        "A" or "ACT" or "ACTIEF" => PolicyStatus.Actief,
        "R" or "ROY" or "GEROYEERD" => PolicyStatus.Geroyeerd,
        "S" or "SCH" or "GESCHORST" => PolicyStatus.Geschorst,
        "P" or "PRO" or "INAANVRAAG" => PolicyStatus.InAanvraag,
        _ => PolicyStatus.Actief
    };

    private static ClaimStatus MapClaimStatus(string code) => code.ToUpperInvariant() switch
    {
        "AFG" or "AFGEHANDELD" => ClaimStatus.Afgehandeld,
        "AFW" or "AFGEWEZEN" => ClaimStatus.Afgewezen,
        "ING" or "INGEDIEND" => ClaimStatus.Ingediend,
        _ => ClaimStatus.InBehandeling
    };
}
