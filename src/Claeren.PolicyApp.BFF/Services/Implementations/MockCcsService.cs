using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Policy;
using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Services.Interfaces;

namespace Claeren.PolicyApp.BFF.Services.Implementations;

public class MockCcsService : ICcsService
{
    public Task<List<Policy>> GetPolissenAsync(string entityId)
    {
        var polissen = MockData.Polissen
            .Where(p => p.EntityId == entityId)
            .ToList();
        return Task.FromResult(polissen);
    }

    public Task<PolicyDetail?> GetPolisDetailAsync(string polisNummer, string entityId)
    {
        MockData.PolisDetails.TryGetValue(polisNummer, out var detail);
        var result = detail?.EntityId == entityId ? detail : null;
        return Task.FromResult(result);
    }

    public Task<List<Claim>> GetClaimsAsync(string entityId)
    {
        var polisNummers = MockData.Polissen
            .Where(p => p.EntityId == entityId)
            .Select(p => p.PolisNummer)
            .ToHashSet();

        var claims = MockData.Claims
            .Where(c => polisNummers.Contains(c.PolisNummer))
            .ToList();
        return Task.FromResult(claims);
    }

    public Task<ClaimResponse> MeldClaimAsync(ClaimRequest request, string entityId)
    {
        var polisBestaatVoorEntity = MockData.Polissen
            .Any(p => p.PolisNummer == request.PolisNummer && p.EntityId == entityId);

        if (!polisBestaatVoorEntity)
            return Task.FromResult(new ClaimResponse(false, null, "Polis niet gevonden voor deze entiteit."));

        var schadeNummer = $"SCH-{DateTime.Now:yyyy}-{Random.Shared.Next(1000, 9999)}";
        return Task.FromResult(new ClaimResponse(true, schadeNummer, null));
    }

    public Task<List<NaverrekenUitvraag>> GetNaverrekenUitvragenAsync(string entityId)
    {
        var polisNummers = MockData.Polissen
            .Where(p => p.EntityId == entityId)
            .Select(p => p.PolisNummer)
            .ToHashSet();

        var uitvragen = MockData.NaverrekenUitvragen
            .Where(u => polisNummers.Contains(u.PolisNummer))
            .ToList();
        return Task.FromResult(uitvragen);
    }

    public Task<bool> BeantwoordNaverrekenUitvraagAsync(NaverrekenAntwoord antwoord, string entityId)
    {
        // In productie: doorsturen naar CCS Level 7
        return Task.FromResult(true);
    }
}
