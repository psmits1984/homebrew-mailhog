using Claeren.PolicyApp.BFF.Models.Auth;
using Claeren.PolicyApp.BFF.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Claeren.PolicyApp.BFF.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("login")]
    [ProducesResponseType(typeof(LoginResponse), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await authService.LoginAsync(request);
        if (result.Token is null && !result.RequiresTwoFactor && !result.RequiresOnboarding)
            return Unauthorized(new { message = "Ongeldige inloggegevens." });

        return Ok(result);
    }

    [HttpPost("2fa/verify")]
    [ProducesResponseType(typeof(LoginResponse), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> VerifyTwoFactor([FromBody] TwoFactorRequest request)
    {
        var result = await authService.VerifyTwoFactorAsync(request);
        if (result.Token is null && !result.RequiresOnboarding)
            return Unauthorized(new { message = "Ongeldige of verlopen code." });

        return Ok(result);
    }

    [HttpPost("onboarding/complete")]
    [ProducesResponseType(typeof(OnboardingResponse), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> CompleteOnboarding([FromBody] OnboardingRequest request)
    {
        var result = await authService.CompleteOnboardingAsync(request);
        if (!result.Success)
            return BadRequest(new { message = result.ErrorMessage });

        return Ok(result);
    }
}
