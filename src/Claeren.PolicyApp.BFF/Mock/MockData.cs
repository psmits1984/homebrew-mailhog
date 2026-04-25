using Claeren.PolicyApp.BFF.Models.Claim;
using Claeren.PolicyApp.BFF.Models.Compliance;
using Claeren.PolicyApp.BFF.Models.Entity;
using Claeren.PolicyApp.BFF.Models.Naverrrekening;
using Claeren.PolicyApp.BFF.Models.Offerte;
using Claeren.PolicyApp.BFF.Models.Payment;
using Claeren.PolicyApp.BFF.Models.Policy;

namespace Claeren.PolicyApp.BFF.Mock;

public static class MockData
{
    public static List<Entity> Entiteiten => new()
    {
        new("ENT-001", "Claeren Holding B.V.", "12345678", EntityType.Zakelijk,
            Hoedanigheid: "Houdstermaatschappij",
            Branche: "Financiële dienstverlening",
            Adres: "Hertogendijerstraat 10",
            Postcode: "5611 PA",
            Woonplaats: "Eindhoven",
            Email: "info@claeren.nl",
            Telefoon: "040-123 4567"),

        new("ENT-002", "Claeren Makelaardij B.V.", "87654321", EntityType.Zakelijk,
            Hoedanigheid: "Assurantietussenpersoon",
            Branche: "Financiële dienstverlening",
            Adres: "Hertogendijerstraat 12",
            Postcode: "5611 PA",
            Woonplaats: "Eindhoven",
            Email: "makelaardij@claeren.nl",
            Telefoon: "040-123 4568"),

        new("ENT-003", "Jan de Vries", string.Empty, EntityType.Particulier,
            Adres: "Dorpstraat 15",
            Postcode: "5611 AZ",
            Woonplaats: "Eindhoven",
            Email: "j.devries@claeren.nl",
            Telefoon: "06-12 34 56 78",
            Geboortedatum: new DateOnly(1980, 3, 15)),
    };

    public static List<Policy> Polissen => new()
    {
        new("POL-2024-001", "Bedrijfsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            2_450.00m, new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BA", "ENT-001",
            AutomatischIncasso: true),
        new("POL-2024-002", "Opstalverzekering Kantoor", "Nationale-Nederlanden", PolicyStatus.Actief,
            1_200.00m, new DateOnly(2024, 3, 1), new DateOnly(2025, 3, 1), "OPSTAL", "ENT-001",
            AutomatischIncasso: false),
        new("POL-2024-003", "Wagenpark Allrisk", "Interpolis", PolicyStatus.Actief,
            8_760.00m, new DateOnly(2024, 1, 15), new DateOnly(2025, 1, 15), "AUTO", "ENT-001",
            AutomatischIncasso: true),
        new("POL-2024-004", "Elektronicaverzekering", "AXA", PolicyStatus.Actief,
            540.00m, new DateOnly(2024, 6, 1), new DateOnly(2025, 6, 1), "ELEKTRO", "ENT-002",
            AutomatischIncasso: false),
        new("POL-2024-005", "Beroepsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            3_100.00m, new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BAV", "ENT-002",
            AutomatischIncasso: true),
        new("POL-2024-006", "Inboedelverzekering", "Centraal Beheer", PolicyStatus.Actief,
            320.00m, new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "INBOEDEL", "ENT-003",
            AutomatischIncasso: false),
        new("POL-2024-007", "Woonhuis All-Risk", "Nationale-Nederlanden", PolicyStatus.Actief,
            780.00m, new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "OPSTAL", "ENT-003",
            AutomatischIncasso: false),
        new("POL-2023-010", "Fietsverzekering", "Centraal Beheer", PolicyStatus.Geroyeerd,
            89.00m, new DateOnly(2022, 5, 1), new DateOnly(2023, 5, 1), "FIETS", "ENT-003",
            AutomatischIncasso: false),
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
        ["POL-2024-002"] = new PolicyDetail(
            "POL-2024-002", "Opstalverzekering Kantoor", "Nationale-Nederlanden", PolicyStatus.Actief,
            1_200.00m, 500.00m,
            new DateOnly(2024, 3, 1), new DateOnly(2025, 3, 1), "OPSTAL", "ENT-001",
            Dekkingen: new()
            {
                new("OPSTAL-BRAND", "Brandschade", 1_500_000m),
                new("OPSTAL-STORM", "Stormschade", 1_500_000m),
                new("OPSTAL-WATER", "Waterschade", 500_000m),
                new("OPSTAL-GLAS", "Glasbreuk", 25_000m),
            },
            Documenten: new()
            {
                new("DOC-020", "Polisblad Opstal 2024", "Polisblad", new DateTime(2024, 3, 5), "/api/documents/DOC-020"),
                new("DOC-021", "Algemene Voorwaarden Opstal", "Voorwaarden", new DateTime(2024, 3, 5), "/api/documents/DOC-021"),
            },
            Historie: new()
            {
                new(new DateTime(2024, 3, 1), "Nieuw afgesloten", 0m, 1_200.00m),
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
        ["POL-2024-004"] = new PolicyDetail(
            "POL-2024-004", "Elektronicaverzekering", "AXA", PolicyStatus.Actief,
            540.00m, 150.00m,
            new DateOnly(2024, 6, 1), new DateOnly(2025, 6, 1), "ELEKTRO", "ENT-002",
            Dekkingen: new()
            {
                new("ELEKTRO-ALL", "All-risk elektronica", 75_000m),
                new("ELEKTRO-DATA", "Dataverlies", 10_000m),
            },
            Documenten: new()
            {
                new("DOC-030", "Polisblad Elektronica 2024", "Polisblad", new DateTime(2024, 6, 5), "/api/documents/DOC-030"),
            },
            Historie: new()
            {
                new(new DateTime(2024, 6, 1), "Nieuw afgesloten", 0m, 540.00m),
            }
        ),
        ["POL-2024-005"] = new PolicyDetail(
            "POL-2024-005", "Beroepsaansprakelijkheid", "Allianz", PolicyStatus.Actief,
            3_100.00m, 2_500.00m,
            new DateOnly(2024, 1, 1), new DateOnly(2025, 1, 1), "BAV", "ENT-002",
            Dekkingen: new()
            {
                new("BAV-PERS", "Personenschade", 2_500_000m),
                new("BAV-VERM", "Vermogensschade", 1_000_000m),
            },
            Documenten: new()
            {
                new("DOC-040", "Polisblad BAV 2024", "Polisblad", new DateTime(2024, 1, 5), "/api/documents/DOC-040"),
                new("DOC-041", "Algemene Voorwaarden BAV", "Voorwaarden", new DateTime(2024, 1, 5), "/api/documents/DOC-041"),
            },
            Historie: new()
            {
                new(new DateTime(2024, 1, 1), "Jaarlijkse verlenging", 2_900.00m, 3_100.00m),
            }
        ),
        ["POL-2024-006"] = new PolicyDetail(
            "POL-2024-006", "Inboedelverzekering", "Centraal Beheer", PolicyStatus.Actief,
            320.00m, 200.00m,
            new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "INBOEDEL", "ENT-003",
            Dekkingen: new()
            {
                new("INBOEDEL-BRAND", "Brand en inbraak", 50_000m),
                new("INBOEDEL-WATER", "Waterschade", 50_000m),
            },
            Documenten: new()
            {
                new("DOC-050", "Polisblad Inboedel 2023", "Polisblad", new DateTime(2023, 9, 5), "/api/documents/DOC-050"),
            },
            Historie: new()
            {
                new(new DateTime(2023, 9, 1), "Jaarlijkse verlenging", 295.00m, 320.00m),
            }
        ),
        ["POL-2024-007"] = new PolicyDetail(
            "POL-2024-007", "Woonhuis All-Risk", "Nationale-Nederlanden", PolicyStatus.Actief,
            780.00m, 500.00m,
            new DateOnly(2023, 9, 1), new DateOnly(2024, 9, 1), "OPSTAL", "ENT-003",
            Dekkingen: new()
            {
                new("WOON-BRAND", "Brandschade", 350_000m),
                new("WOON-STORM", "Stormschade", 350_000m),
                new("WOON-WATER", "Waterschade", 100_000m),
                new("WOON-GLAS", "Glasbreuk", 5_000m),
            },
            Documenten: new()
            {
                new("DOC-060", "Polisblad Woonhuis 2023", "Polisblad", new DateTime(2023, 9, 5), "/api/documents/DOC-060"),
            },
            Historie: new()
            {
                new(new DateTime(2023, 9, 1), "Jaarlijkse verlenging", 740.00m, 780.00m),
            }
        ),
    };

    public static List<Payment> Betalingen => new()
    {
        new("PAY-2024-001", "ENT-001", "POL-2024-001", "Bedrijfsaansprakelijkheid",
            new DateTime(2024, 1, 15), 2_450.00m, PaymentStatus.Betaald, "F-2024-001",
            "/api/facturen/PAY-2024-001"),
        new("PAY-2024-002", "ENT-001", "POL-2024-002", "Opstalverzekering Kantoor",
            new DateTime(2024, 3, 10), 1_200.00m, PaymentStatus.Betaald, "F-2024-002",
            "/api/facturen/PAY-2024-002"),
        new("PAY-2024-003", "ENT-001", "POL-2024-003", "Wagenpark Allrisk",
            new DateTime(2024, 1, 20), 8_760.00m, PaymentStatus.Betaald, "F-2024-003",
            "/api/facturen/PAY-2024-003"),
        new("PAY-2024-004", "ENT-001", "POL-2024-003", "Wagenpark Allrisk (kwartaal)",
            new DateTime(2024, 4, 20), 2_190.00m, PaymentStatus.Openstaand, "F-2024-004",
            "/api/facturen/PAY-2024-004"),
        new("PAY-2024-005", "ENT-002", "POL-2024-004", "Elektronicaverzekering",
            new DateTime(2024, 6, 5), 540.00m, PaymentStatus.Betaald, "F-2024-005",
            "/api/facturen/PAY-2024-005"),
        new("PAY-2024-006", "ENT-002", "POL-2024-005", "Beroepsaansprakelijkheid",
            new DateTime(2024, 1, 10), 3_100.00m, PaymentStatus.Betaald, "F-2024-006",
            "/api/facturen/PAY-2024-006"),
        new("PAY-2024-007", "ENT-002", "POL-2024-005", "Beroepsaansprakelijkheid",
            new DateTime(2024, 4, 10), 775.00m, PaymentStatus.Mislukt, "F-2024-007",
            "/api/facturen/PAY-2024-007"),
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

    public static List<Offerte> Offertes => new()
    {
        new("OFF-2025-001", "ENT-001",
            "OFF-2025-001", "Bedrijfsschadeverzekering uitbreiding",
            RelatieSoort.Zakelijk, OfferteStatus.Verzonden,
            "BS", "Bedrijfsschade + Extra kosten",
            3_850.00m,
            new DateOnly(2025, 5, 1), new DateOnly(2025, 6, 30),
            new DateTime(2025, 4, 10),
            KvkNummer: "12345678",
            ContactpersoonEmail: "info@claeren.nl"),

        new("OFF-2025-002", "ENT-001",
            "OFF-2025-002", "Cyber & Dataverzekering",
            RelatieSoort.Zakelijk, OfferteStatus.Concept,
            "CYBER", "Cyber liability + Data recovery",
            2_200.00m,
            new DateOnly(2025, 6, 1), new DateOnly(2025, 7, 31),
            new DateTime(2025, 4, 15),
            KvkNummer: "12345678",
            ContactpersoonEmail: "info@claeren.nl"),

        new("OFF-2025-003", "ENT-002",
            "OFF-2025-003", "Beroepsaansprakelijkheid verlenging",
            RelatieSoort.Zakelijk, OfferteStatus.Geaccordeerd,
            "BAV", "Beroepsaansprakelijkheid tot €2.5M",
            3_250.00m,
            new DateOnly(2025, 1, 1), new DateOnly(2026, 1, 1),
            new DateTime(2025, 3, 1),
            KvkNummer: "87654321",
            ContactpersoonEmail: "makelaardij@claeren.nl"),

        new("OFF-2025-004", "ENT-002",
            "OFF-2025-004", "Wagenpark uitbreiding 3 voertuigen",
            RelatieSoort.Zakelijk, OfferteStatus.Geweigerd,
            "AUTO", "WA + Allrisk 3 voertuigen",
            4_100.00m,
            new DateOnly(2025, 3, 1), new DateOnly(2025, 4, 30),
            new DateTime(2025, 2, 20),
            KvkNummer: "87654321",
            ContactpersoonEmail: "makelaardij@claeren.nl"),

        new("OFF-2025-005", "ENT-003",
            "OFF-2025-005", "Overlijdensrisicoverzekering",
            RelatieSoort.Particulier, OfferteStatus.Verzonden,
            "ORV", "Overlijdensrisico €250.000",
            680.00m,
            new DateOnly(2025, 5, 15), new DateOnly(2025, 6, 30),
            new DateTime(2025, 4, 18),
            ContactpersoonEmail: "j.devries@claeren.nl"),

        new("OFF-2025-006", "ENT-001",
            "OFF-2025-006", "Gebouwenverzekering Hoofdkantoor",
            RelatieSoort.Zakelijk, OfferteStatus.Getekend,
            "OPSTAL", "All-risk opstal met glasdekking",
            5_600.00m,
            new DateOnly(2025, 1, 1), new DateOnly(2026, 1, 1),
            new DateTime(2024, 12, 1),
            KvkNummer: "12345678",
            ContactpersoonEmail: "info@claeren.nl"),
    };
}
