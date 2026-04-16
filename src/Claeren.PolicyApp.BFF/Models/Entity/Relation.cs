namespace Claeren.PolicyApp.BFF.Models.Entity;

public record Relation(
    string RelatieNummer,
    string Naam,
    string Email,
    List<Entity> Entiteiten
);
