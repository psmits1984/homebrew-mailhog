namespace Claeren.PolicyApp.BFF.Models.Auth;

public record LoginResponse(
    bool RequiresTwoFactor,
    bool RequiresOnboarding,
    string? Token,
    string? TwoFactorSessionToken
);
