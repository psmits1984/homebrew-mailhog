namespace Claeren.PolicyApp.BFF.Models.Auth;

public record TwoFactorRequest(string SessionToken, string Code);
