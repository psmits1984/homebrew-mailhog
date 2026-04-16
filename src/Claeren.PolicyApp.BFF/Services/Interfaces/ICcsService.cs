using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Policy;

namespace Claeren.PolicyApp.BFF.Services.Interfaces;

public interface ICcsService
{
    Task<List<Policy>> GetPolissenAsync(string entityId);
    Task<PolicyDetail?> GetPolisDetailAsync(string polisNummer, string entityId);
    Task<List<Claim>> GetClaimsAsync(string entityId);
    Task<ClaimResponse> MeldClaimAsync(ClaimRequest request, string entityId);
    Task<List<NaverrekenUitvraag>> GetNaverrekenUitvragenAsync(string entityId);
    Task<bool> BeantwoordNaverrekenUitvraagAsync(NaverrekenAntwoord antwoord, string entityId);
}
