namespace Claeren.PolicyApp.BFF.Models.Entity;

public record Entity(
    string Id,
    string Naam,
    string KvkNummer,
    EntityType Type
);

public enum EntityType
{
    Particulier,
    Zakelijk
}
