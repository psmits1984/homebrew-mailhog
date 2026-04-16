using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Entity;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Policy;

namespace Claeren.PolicyApp.BFF.Mock;

public static class MockData
{
    public static List<Entity> Entiteiten => new()
    {
        new("ENT-001", "Claeren Holding B.V.", "12345678", EntityType.Zakelijk),
        new("ENT-002", "Claeren Makelaardij B.V.", "87654321", EntityType.Zakelijk),
        new("ENT-003", "Jan de Vries", string.Empty, EntityType.Particulier),
    };

    public static List<Policy> Polissen => new()
    {
        new("POL-2024-001", "Bedrijfsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            2_450.00m, new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BA", "ENT-001"),
        new("POL-2024-002", "Opstalverzekering Kantoor", "Nationale-Nederlanden", PolicyStatus.Actief,
            1_200.00m, new DateOnly(2024, 3, 1), new DateOnly(2025, 3, 1), "OPSTAL", "ENT-001"),
        new("POL-2024-003", "Wagenpark Allrisk", "Interpolis", PolicyStatus.Actief,
            8_760.00m, new DateOnly(2024, 1, 15), new DateOnly(2025, 1, 15), "AUTO", "ENT-001"),
        new("POL-2024-004", "Elektronicaverzekering", "AXA", PolicyStatus.Actief,
            540.00m, new DateOnly(2024, 6, 1), new DateOnly(2025, 6, 1), "ELEKTRO", "ENT-002"),
        new("POL-2024-005", "Beroepsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            3_100.00m, new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BAV", "ENT-002"),
        new("POL-2024-006", "Inboedelverzekering", "Centraal Beheer", PolicyStatus.Actief,
            320.00m, new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "INBOEDEL", "ENT-003"),
        new("POL-2024-007", "Woonhuis All-Risk", "Nationale-Nederlanden", PolicyStatus.Actief,
            780.00m, new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "OPSTAL", "ENT-003"),
        new("POL-2023-010", "Fietsverzekering", "Centraal Beheer", PolicyStatus.Geroyeerd,
            89.00m, new DateOnly(2022, 5, 1), new DateOnly(2023, 5, 1), "FIETS", "ENT-003"),
    };

    public static Dictionary<string, PolicyDetail> PolisDetails => new()
    {
        ["POL-2024-001"] = new PolicyDetail(
            "POL-2024-001", "Bedrijfsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            2_450.00m, 500.00m,
            new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BA", "ENT-001",
            Dekkingen: new()
            {
                new("BA-PERS", "Personenschade", 2_500_000m),
                new("BA-ZAAK", "Zaakschade", 1_000_000m),
                new("BA-VERM", "Vermogensschade", 500_000m),
            },
            Documenten: new()
            {
                new("DOC-001", "Polisblad 2024", "Polisblad", new DateTime(2024, 1, 5), "/api/documents/DOC-001"),
                new("DOC-002", "Algemene Voorwaarden BA", "Voorwaarden", new DateTime(2024, 1, 5), "/api/documents/DOC-002"),
                new("DOC-003", "Groene Kaart 2024", "Certificaat", new DateTime(2024, 1, 10), "/api/documents/DOC-003"),
            },
            Historie: new()
            {
                new(new DateTime(2024, 1, 1), "Jaarlijkse verlenging", 2_300.00m, 2_450.00m),
                new(new DateTime(2023, 1, 1), "Jaarlijkse verlenging", 2_100.00m, 2_300.00m),
            }
        ),
        ["POL-2024-003"] = new PolicyDetail(
            "POL-2024-003", "Wagenpark Allrisk", "Interpolis", PolicyStatus.Actief,
            8_760.00m, 250.00m,
            new DateOnly(2024, 1, 15), new DateOnly(2025, 1, 15), "AUTO", "ENT-001",
            Dekkingen: new()
            {
                new("WA", "Wettelijke Aansprakelijkheid", null),
                new("CASCO", "Allrisk Casco", null),
                new("OCC", "Schade Inzittenden", 500_000m),
            },
            Documenten: new()
            {
                new("DOC-010", "Polisblad Wagenpark 2024", "Polisblad", new DateTime(2024, 1, 20), "/api/documents/DOC-010"),
                new("DOC-011", "Kentekenlijst", "Bijlage", new DateTime(2024, 1, 20), "/api/documents/DOC-011"),
            },
            Historie: new()
            {
                new(new DateTime(2024, 1, 15), "Kenteken toegevoegd: 01-ABC-2", 8_400.00m, 8_760.00m),
                new(new DateTime(2023, 1, 15), "Jaarlijkse verlenging", 7_900.00m, 8_400.00m),
            }
        ),
    };

    public static List<Claim> Claims => new()
    {
        new("SCH-2024-0042", "POL-2024-003", "Aanrijding parkeerplaats Eindhoven",
            ClaimStatus.InBehandeling, new DateTime(2024, 3, 14), new DateTime(2024, 3, 15),
            3_200.00m, null),
        new("SCH-2024-0018", "POL-2024-001", "Waterschade kantoor",
            ClaimStatus.Afgehandeld, new DateTime(2024, 2, 2), new DateTime(2024, 2, 3),
            12_500.00m, 11_800.00m),
        new("SCH-2023-0156", "POL-2024-003", "Diefstal navigatiesysteem",
            ClaimStatus.Afgewezen, new DateTime(2023, 11, 20), new DateTime(2023, 11, 21),
            850.00m, null),
    };

    public static List<NaverrekenUitvraag> NaverrekenUitvragen => new()
    {
        new(
            "NV-2024-001", "POL-2024-001",
            "Naverrekeningsgegevens Bedrijfsaansprakelijkheid 2024",
            2024, new DateTime(2025, 2, 1),
            Vragen: new()
            {
                new("V1", "Wat was de totale omzet in 2024?", "number", true, null),
                new("V2", "Hoeveel medewerkers (FTE) had u gemiddeld in 2024?", "number", true, null),
                new("V3", "Zijn er in 2024 nieuwe activiteiten gestart?", "select", true,
                    new() { "Ja", "Nee" }),
                new("V4", "Zo ja, omschrijf de nieuwe activiteiten", "text", false, null),
            }
        ),
        new(
            "NV-2024-002", "POL-2024-005",
            "Naverrekeningsgegevens Beroepsaansprakelijkheid 2024",
            2024, new DateTime(2025, 2, 1),
            Vragen: new()
            {
                new("V1", "Wat was de totale fee-omzet in 2024?", "number", true, null),
                new("V2", "Hoeveel opdrachten zijn in 2024 afgerond?", "number", true, null),
            }
        ),
    };

    public static List<Models.Auth.MockUser> Users => new()
    {
        new("user-001", "j.devries@claeren.nl", "Welkom01!", "ENT-003"),
        new("user-002", "zakelijk@claeren.nl", "Welkom02!", "ENT-001", "ENT-002"),
    };
}
