namespace Claeren.PolicyApp.BFF.Models.Auth;

public record MockUser(string Id, string Username, string Password, params string[] EntityIds)
{
    public bool OnboardingCompleted { get; init; } = false;
}
