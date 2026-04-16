using Claeren.PolicyApp.BFF.Models.Auth;
using Claeren.PolicyApp.BFF.Models.Entity;

namespace Claeren.PolicyApp.BFF.Services.Interfaces;

public interface IAuthService
{
    Task<LoginResponse> LoginAsync(LoginRequest request);
    Task<LoginResponse> VerifyTwoFactorAsync(TwoFactorRequest request);
    Task<OnboardingResponse> CompleteOnboardingAsync(OnboardingRequest request);
    Task<List<Entity>> GetEntiteitenAsync(string userId);
}
