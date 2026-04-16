namespace Claeren.PolicyApp.BFF.Infrastructure.Auth;

public class KeycloakOptions
{
    public const string Section = "Keycloak";
    public string Authority { get; init; } = string.Empty;       // bijv. https://auth.claeren.nl/realms/claeren
    public string ClientId { get; init; } = string.Empty;
    public string ClientSecret { get; init; } = string.Empty;
    public string AdminApiUrl { get; init; } = string.Empty;     // bijv. https://auth.claeren.nl/admin/realms/claeren
    public string AdminClientId { get; init; } = string.Empty;
    public string AdminClientSecret { get; init; } = string.Empty;
}
