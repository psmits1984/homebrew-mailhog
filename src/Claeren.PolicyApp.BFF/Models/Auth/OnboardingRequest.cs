namespace Claeren.PolicyApp.BFF.Models.Auth;

public record OnboardingRequest(
    string SessionToken,
    string Geboortedatum,    // dd-MM-yyyy
    string Postcode,
    string Huisnummer
);
