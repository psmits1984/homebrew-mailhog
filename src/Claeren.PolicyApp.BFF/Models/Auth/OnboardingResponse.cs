namespace Claeren.PolicyApp.BFF.Models.Auth;

public record OnboardingResponse(bool Success, string? Token, string? ErrorMessage);
