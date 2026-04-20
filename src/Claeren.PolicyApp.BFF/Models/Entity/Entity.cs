namespace Claeren.PolicyApp.BFF.Models.Entity;

public record Entity(
    string Id,
    string Naam,
    string KvkNummer,
    EntityType Type,
    string? Hoedanigheid = null,
    string? Branche = null,
    string? Adres = null,
    string? Postcode = null,
    string? Woonplaats = null,
    string? Email = null,
    string? Telefoon = null,
    DateOnly? Geboortedatum = null
);

public enum EntityType
{
    Particulier,
    Zakelijk
}
