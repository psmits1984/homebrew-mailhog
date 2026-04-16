using System.Net.Http.Headers;
using System.Text.Json;
using Claeren.PolicyApp.BFF.Infrastructure.Auth;
using Claeren.PolicyApp.BFF.Models.Auth;
using Claeren.PolicyApp.BFF.Models.Entity;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace Claeren.PolicyApp.BFF.Services.Implementations;

// Vervangt AuthService (mock) — gebruikt Keycloak als Identity Provider.
// Keycloak beheert gebruikers, wachtwoorden, 2FA en de koppeling entiteit-relatie.
public class KeycloakAuthService(
    HttpClient httpClient,
    IOptions<KeycloakOptions> options,
    ILogger<KeycloakAuthService> logger) : IAuthService
{
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNameCaseInsensitive = true };
    private readonly KeycloakOptions _opts = options.Value;

    // Stap 1: Valideer credentials via Keycloak Resource Owner Password Credentials flow.
    // Keycloak geeft bij 2FA ingeschakeld een partial token terug (MFA challenge).
    public async Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        logger.LogInformation("Keycloak: login aanvraag voor {Username}", request.Username);

        var tokenResponse = await RequestToken(new Dictionary<string, string>
        {
            ["grant_type"] = "password",
            ["client_id"] = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["username"] = request.Username,
            ["password"] = request.Password,
            ["scope"] = "openid profile email",
        });

        if (tokenResponse is null)
            return new LoginResponse(false, false, null, null);

        // Als Keycloak een "mfa_token" claim teruggeeft: 2FA vereist
        if (tokenResponse.ContainsKey("mfa_token"))
        {
            return new LoginResponse(
                RequiresTwoFactor: true,
                RequiresOnboarding: false,
                Token: null,
                TwoFactorSessionToken: tokenResponse["mfa_token"]
            );
        }

        var jwt = tokenResponse.GetValueOrDefault("access_token");
        return new LoginResponse(false, false, jwt, null);
    }

    // Stap 2: Verifieer TOTP-code bij Keycloak
    public async Task<LoginResponse> VerifyTwoFactorAsync(TwoFactorRequest request)
    {
        logger.LogInformation("Keycloak: 2FA verificatie");

        var tokenResponse = await RequestToken(new Dictionary<string, string>
        {
            ["grant_type"] = "urn:ietf:params:oauth:grant-type:mfa",
            ["client_id"] = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["mfa_token"] = request.SessionToken,
            ["otp"] = request.Code,
        });

        if (tokenResponse is null)
            return new LoginResponse(false, false, null, null);

        var jwt = tokenResponse.GetValueOrDefault("access_token");
        var requiresOnboarding = !tokenResponse.ContainsKey("access_token") ||
                                  IsFirstLogin(tokenResponse);

        if (requiresOnboarding)
        {
            return new LoginResponse(false, true, null, tokenResponse.GetValueOrDefault("session_state"));
        }

        return new LoginResponse(false, false, jwt, null);
    }

    // Stap 3: Eerste login — valideer gegevens tegen CCS en activeer account in Keycloak
    public async Task<OnboardingResponse> CompleteOnboardingAsync(OnboardingRequest request)
    {
        logger.LogInformation("Keycloak: onboarding afronden");

        // Haal admin token op voor Keycloak Admin API
        var adminToken = await GetAdminToken();
        if (adminToken is null)
            return new OnboardingResponse(false, null, "Interne fout bij activatie.");

        // Markeer gebruiker als geverifieerd via Keycloak Admin API
        var userId = await GetUserIdFromSession(request.SessionToken, adminToken);
        if (userId is null)
            return new OnboardingResponse(false, null, "Sessie verlopen.");

        var activated = await ActivateUser(userId, adminToken);
        if (!activated)
            return new OnboardingResponse(false, null, "Activatie mislukt.");

        // Haal eindgebruiker token op na activatie
        var tokenResponse = await RequestToken(new Dictionary<string, string>
        {
            ["grant_type"] = "urn:keycloak:params:grant-type:token-exchange",
            ["client_id"] = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["subject_token"] = request.SessionToken,
            ["requested_token_type"] = "urn:ietf:params:oauth:token-type:access_token",
        });

        var jwt = tokenResponse?.GetValueOrDefault("access_token");
        return jwt is not null
            ? new OnboardingResponse(true, jwt, null)
            : new OnboardingResponse(false, null, "Token uitgifte mislukt.");
    }

    // Haal entiteiten op uit Keycloak user attributes (entityIds worden opgeslagen als claim)
    public async Task<List<Entity>> GetEntiteitenAsync(string userId)
    {
        logger.LogInformation("Keycloak: entiteiten ophalen voor gebruiker {UserId}", userId);

        var adminToken = await GetAdminToken();
        if (adminToken is null) return [];

        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        var response = await httpClient.GetAsync($"{_opts.AdminApiUrl}/users/{userId}");
        if (!response.IsSuccessStatusCode) return [];

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);

        if (!doc.RootElement.TryGetProperty("attributes", out var attrs)) return [];
        if (!attrs.TryGetProperty("entityIds", out var entityIdsEl)) return [];

        var entityIds = entityIdsEl.EnumerateArray()
            .Select(e => e.GetString() ?? string.Empty)
            .Where(s => !string.IsNullOrEmpty(s))
            .ToList();

        // TODO: ophalen van entiteitsnamen uit CCS of een interne lookup
        return entityIds.Select(id => new Entity(id, id, string.Empty, EntityType.Zakelijk)).ToList();
    }

    private async Task<Dictionary<string, string>?> RequestToken(Dictionary<string, string> formData)
    {
        try
        {
            var response = await httpClient.PostAsync(
                $"{_opts.Authority}/protocol/openid-connect/token",
                new FormUrlEncodedContent(formData));

            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Keycloak token request mislukt: {StatusCode}", response.StatusCode);
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOpts);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Keycloak token request exceptie");
            return null;
        }
    }

    private async Task<string?> GetAdminToken()
    {
        var response = await RequestToken(new Dictionary<string, string>
        {
            ["grant_type"] = "client_credentials",
            ["client_id"] = _opts.AdminClientId,
            ["client_secret"] = _opts.AdminClientSecret,
        });
        return response?.GetValueOrDefault("access_token");
    }

    private async Task<string?> GetUserIdFromSession(string sessionToken, string adminToken)
    {
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        // Keycloak session → user ID lookup via token introspect
        var introspect = await RequestToken(new Dictionary<string, string>
        {
            ["grant_type"] = "urn:ietf:params:oauth:grant-type:token-exchange",
            ["client_id"] = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["subject_token"] = sessionToken,
        });

        return introspect?.GetValueOrDefault("sub");
    }

    private async Task<bool> ActivateUser(string userId, string adminToken)
    {
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        var payload = JsonSerializer.Serialize(new
        {
            attributes = new { onboardingCompleted = new[] { "true" } }
        });

        var response = await httpClient.PutAsync(
            $"{_opts.AdminApiUrl}/users/{userId}",
            new StringContent(payload, System.Text.Encoding.UTF8, "application/json"));

        return response.IsSuccessStatusCode;
    }

    private static bool IsFirstLogin(Dictionary<string, string> tokenResponse) =>
        tokenResponse.TryGetValue("onboarding_completed", out var val) && val == "false";
}
