using System.Net.Http.Headers;
using System.Text.Json;
using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Policy;
using Claeren.PolicyApp.BFF.Services.Ccs;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace Claeren.PolicyApp.BFF.Services.Implementations;

public class CcsOptions
{
    public const string Section = "Ccs";
    public string BaseUrl { get; init; } = string.Empty;
    public string ApiKey { get; init; } = string.Empty;
    public string RelatiePrefixZakelijk { get; init; } = "ZAK";
    public string RelatiePrefixParticulier { get; init; } = "PAR";
}

public class CcsService(HttpClient httpClient, IOptions<CcsOptions> options, ILogger<CcsService> logger)
    : ICcsService
{
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNameCaseInsensitive = true };
    private readonly CcsOptions _opts = options.Value;

    public async Task<List<Policy>> GetPolissenAsync(string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: polissen ophalen voor relatie {RelatieId}", relatieId);

        var response = await httpClient.GetAsync($"/api/v1/relaties/{relatieId}/polissen?soort=schade");
        response.EnsureSuccessStatusCode();

        var ccsPolissen = await Deserialize<List<CcsPolisResponse>>(response);
        return ccsPolissen.Select(p => CcsMapper.ToPolicy(p, entityId)).ToList();
    }

    public async Task<PolicyDetail?> GetPolisDetailAsync(string polisNummer, string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: polisdetail ophalen {PolisNummer}", polisNummer);

        var response = await httpClient.GetAsync($"/api/v1/relaties/{relatieId}/polissen/{polisNummer}");

        if (response.StatusCode == System.Net.HttpStatusCode.NotFound) return null;
        response.EnsureSuccessStatusCode();

        var ccsDetail = await Deserialize<CcsPolisDetailResponse>(response);
        return CcsMapper.ToPolisDetail(ccsDetail, entityId);
    }

    public async Task<List<Claim>> GetClaimsAsync(string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: schades ophalen voor relatie {RelatieId}", relatieId);

        var response = await httpClient.GetAsync($"/api/v1/relaties/{relatieId}/schades");
        response.EnsureSuccessStatusCode();

        var ccsSchades = await Deserialize<List<CcsSchadeResponse>>(response);
        return ccsSchades.Select(CcsMapper.ToClaim).ToList();
    }

    public async Task<ClaimResponse> MeldClaimAsync(ClaimRequest request, string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: schade melden voor polis {PolisNummer}", request.PolisNummer);

        var ccsRequest = new CcsMeldSchadeRequest(
            request.PolisNummer,
            request.SchadeDatum.ToString("yyyy-MM-dd"),
            request.Omschrijving,
            request.Locatie,
            request.GeschadeSchadeEstimatie
        );

        var response = await httpClient.PostAsJsonAsync(
            $"/api/v1/relaties/{relatieId}/schades", ccsRequest);
        response.EnsureSuccessStatusCode();

        var ccsResult = await Deserialize<CcsMeldSchadeResponse>(response);
        return new ClaimResponse(ccsResult.Geslaagd, ccsResult.SchadenummerCcs, ccsResult.Foutmelding);
    }

    public async Task<List<NaverrekenUitvraag>> GetNaverrekenUitvragenAsync(string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: naverrekeningsuitvragen ophalen voor {RelatieId}", relatieId);

        var response = await httpClient.GetAsync($"/api/v1/relaties/{relatieId}/naverrrekening/uitvragen");
        response.EnsureSuccessStatusCode();

        var ccsUitvragen = await Deserialize<List<CcsNaverrekenUitvraagResponse>>(response);
        return ccsUitvragen.Select(CcsMapper.ToUitvraag).ToList();
    }

    public async Task<bool> BeantwoordNaverrekenUitvraagAsync(NaverrekenAntwoord antwoord, string entityId)
    {
        var relatieId = ToRelatieId(entityId);
        logger.LogInformation("CCS: naverrekeningsantwoorden indienen {UitvraagId}", antwoord.UitvraagId);

        var ccsRequest = new CcsNaverrekenAntwoordRequest(
            antwoord.UitvraagId,
            antwoord.Antwoorden.Select(a => new CcsVraagAntwoordDto(a.VraagId, a.Waarde)).ToList()
        );

        var response = await httpClient.PostAsJsonAsync(
            $"/api/v1/relaties/{relatieId}/naverrrekening/uitvragen/{antwoord.UitvraagId}/antwoorden",
            ccsRequest);

        return response.IsSuccessStatusCode;
    }

    // Vertaalt een interne entity-ID naar het CCS relatie-ID formaat.
    // Aanpassen op basis van de werkelijke CCS Level 7 relatie-ID conventies.
    private string ToRelatieId(string entityId) => entityId;

    private static async Task<T> Deserialize<T>(HttpResponseMessage response)
    {
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(json, JsonOpts)
               ?? throw new InvalidOperationException("Leeg antwoord van CCS.");
    }
}
