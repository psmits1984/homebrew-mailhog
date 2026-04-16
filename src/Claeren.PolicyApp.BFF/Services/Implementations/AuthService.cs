using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Claeren.PolicyApp.BFF.Models.Auth;
using Claeren.PolicyApp.BFF.Models.Entity;
using Claeren.PolicyApp.BFF.Mock;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.IdentityModel.Tokens;

namespace Claeren.PolicyApp.BFF.Services.Implementations;

public class AuthService(IConfiguration config) : IAuthService
{
    private static readonly Dictionary<string, (string UserId, DateTime Expiry)> _sessions = new();

    public Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        var user = MockData.Users.FirstOrDefault(u =>
            u.Username.Equals(request.Username, StringComparison.OrdinalIgnoreCase) &&
            u.Password == request.Password);

        if (user is null)
            return Task.FromResult(new LoginResponse(false, false, null, null));

        var sessionToken = Guid.NewGuid().ToString();
        _sessions[sessionToken] = (user.Id, DateTime.UtcNow.AddMinutes(5));

        return Task.FromResult(new LoginResponse(
            RequiresTwoFactor: true,
            RequiresOnboarding: !user.OnboardingCompleted,
            Token: null,
            TwoFactorSessionToken: sessionToken
        ));
    }

    public Task<LoginResponse> VerifyTwoFactorAsync(TwoFactorRequest request)
    {
        // Mock: accept code "123456" always
        if (!_sessions.TryGetValue(request.SessionToken, out var session) ||
            session.Expiry < DateTime.UtcNow)
            return Task.FromResult(new LoginResponse(false, false, null, null));

        if (request.Code != "123456")
            return Task.FromResult(new LoginResponse(false, false, null, null));

        var user = MockData.Users.First(u => u.Id == session.UserId);
        _sessions.Remove(request.SessionToken);

        if (!user.OnboardingCompleted)
        {
            var onboardingSession = Guid.NewGuid().ToString();
            _sessions[onboardingSession] = (user.Id, DateTime.UtcNow.AddMinutes(15));
            return Task.FromResult(new LoginResponse(false, true, null, onboardingSession));
        }

        var token = GenerateJwt(user.Id, user.EntityIds);
        return Task.FromResult(new LoginResponse(false, false, token, null));
    }

    public Task<OnboardingResponse> CompleteOnboardingAsync(OnboardingRequest request)
    {
        if (!_sessions.TryGetValue(request.SessionToken, out var session) ||
            session.Expiry < DateTime.UtcNow)
            return Task.FromResult(new OnboardingResponse(false, null, "Sessie verlopen."));

        // Mock gegevenscheck: postcode 5611 + huisnummer 1 = OK
        if (request.Postcode != "5611AZ" || request.Huisnummer != "1")
            return Task.FromResult(new OnboardingResponse(false, null, "Gegevens komen niet overeen."));

        var user = MockData.Users.First(u => u.Id == session.UserId);
        _sessions.Remove(request.SessionToken);

        var token = GenerateJwt(user.Id, user.EntityIds);
        return Task.FromResult(new OnboardingResponse(true, token, null));
    }

    public Task<List<Entity>> GetEntiteitenAsync(string userId)
    {
        var user = MockData.Users.FirstOrDefault(u => u.Id == userId);
        if (user is null) return Task.FromResult(new List<Entity>());

        var entiteiten = MockData.Entiteiten
            .Where(e => user.EntityIds.Contains(e.Id))
            .ToList();
        return Task.FromResult(entiteiten);
    }

    private string GenerateJwt(string userId, string[] entityIds)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Secret"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId),
            new("entityIds", string.Join(",", entityIds)),
        };

        var token = new JwtSecurityToken(
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
