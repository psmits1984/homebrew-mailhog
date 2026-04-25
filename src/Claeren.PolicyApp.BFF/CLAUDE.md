# BFF — Claeren.PolicyApp.BFF

## Stack

- .NET 8, ASP.NET Core Web API
- Auth: JWT Bearer (eigen mock AuthService) + optioneel Keycloak
- Mock modus: `Features__MockCcs=true` (standaard in dev)
- Docker: `Dockerfile` in repo root van BFF
- Health check endpoint: `GET /health`

## Controllers & endpoints

### AuthController
```
POST /api/auth/login              LoginRequest → LoginResponse (JWT)
POST /api/auth/2fa/verify         TwoFactorRequest → JWT of requiresOnboarding
POST /api/auth/onboarding/complete OnboardingRequest → JWT
```

### EntityController
```
GET /api/entiteiten               Lijst van entiteiten voor ingelogde user
```

### PolicyController
```
GET /api/entiteiten/{entityId}/polissen           Lijst polissen
GET /api/entiteiten/{entityId}/polissen/{nr}      Polisdetail
```

### PaymentController
```
GET /api/entiteiten/{entityId}/betalingen         Lijst betalingen + factuurlinks
```

### MachtigingController
```
POST /api/machtigingen            SEPA-machtiging aanmaken
```

### ClaimController
```
POST /api/entiteiten/{entityId}/claims            Nieuwe claim
```

### NaverrekenController
```
GET  /api/entiteiten/{entityId}/naverrrekening           Uitvraag ophalen
POST /api/entiteiten/{entityId}/naverrrekening/{id}/antwoorden  Antwoorden indienen
```

### OfferteController
```
GET  /api/entiteiten/{entityId}/offertes          Lijst offertes
GET  /api/offertes/{id}                           Offerte detail
POST /api/offertes/{id}/accorderen                Status → Geaccordeerd
POST /api/offertes/{id}/weigeren                  Status → Geweigerd
```

### VnabController (VNAB Sanctieplatform proxy)
```
POST /api/compliance/check        SOAP proxy → SearchPersonsByCriteria / GetOrganisationsByKvK
                                  Mock: 70% Goedgekeurd, 30% HandmatigeReview
```

### UboController
```
POST /api/compliance/ubo          UBO/CC formulier indienen
GET  /api/compliance/{entityId}/status  Compliance status
```

### SlotverklaringController
```
POST /api/slotverklaringen/{offerteId}/otp          OTP genereren (SHA256 hash opgeslagen)
POST /api/slotverklaringen/{offerteId}/ondertekenen OTP verifiëren + HMAC-SHA256 audittrail
```

### DocumentController / FactuurController
```
GET /api/documents/{id}   Mock PDF download
GET /api/facturen/{id}    Mock factuur PDF download
```

## Autorisatie

Elke controller controleert `UserHeeftToegang(entityId)`:

```csharp
var entityIdsClaim = User.FindFirst("entityIds")?.Value ?? string.Empty;
return entityIdsClaim.Split(',').Contains(entityId);
```

JWT bevat claim `entityIds` als kommagescheiden string (bijv. `"ENT-001,ENT-002"`).

## Mock data (`Mock/MockData.cs`)

### Gebruikers
| Email                 | Wachtwoord | EntityIds         |
|-----------------------|------------|-------------------|
| zakelijk@claeren.nl   | Welkom02!  | ENT-001, ENT-002  |
| j.devries@claeren.nl  | Welkom01!  | ENT-003           |

### Entiteiten
- `ENT-001` — Claeren BV (zakelijk, KvK 12345678)
- `ENT-002` — Makelaardij Claeren (zakelijk, KvK 87654321)
- `ENT-003` — J. de Vries (particulier)

### Polissen per entiteit

**ENT-001:**
- `POL-2024-001` — Bedrijfsaansprakelijkheid, Allianz, €2.450/jr, incasso ✓
- `POL-2024-002` — Opstalverzekering Kantoor, NN, €1.200/jr, incasso ✗
- `POL-2024-003` — Wagenpark Allrisk, Interpolis, €8.760/jr, incasso ✓

**ENT-002:**
- `POL-2024-004` — Elektronicaverzekering, AXA, €540/jr, incasso ✗
- `POL-2024-005` — Beroepsaansprakelijkheid, Allianz, €3.100/jr, incasso ✓

**ENT-003:**
- `POL-2024-006` — Inboedelverzekering, Centraal Beheer, €320/jr, incasso ✗
- `POL-2024-007` — Woonhuis All-Risk, NN, €780/jr, incasso ✗
- `POL-2023-010` — Fietsverzekering (Geroyeerd)

Alle polissen hebben een `PolisDetails` entry met dekkingen, documenten en premiehistorie.

### Offertes per entiteit

**ENT-001:**
- `OFF-2025-001` — Bedrijfsschadeverzekering, **Verzonden** (actie vereist), €3.850/jr
- `OFF-2025-002` — Cyber & Dataverzekering, Concept, €2.200/jr
- `OFF-2025-006` — Gebouwenverzekering, Getekend, €5.600/jr

**ENT-002:**
- `OFF-2025-003` — Beroepsaansprakelijkheid verlenging, Geaccordeerd, €3.250/jr
- `OFF-2025-004` — Wagenpark uitbreiding, Geweigerd, €4.100/jr

**ENT-003:**
- `OFF-2025-005` — Overlijdensrisicoverzekering, **Verzonden** (actie vereist), €680/jr

### Betalingen
Betalingen voor ENT-001 (POL-2024-001..003) en ENT-002 (POL-2024-004..005).
Status: Betaald / Openstaand / Mislukt.

## JSON serialisatie

Enums worden geserialiseerd als strings via `JsonStringEnumConverter` (geconfigureerd in `Program.cs`).

Voorbeeld: `OfferteStatus.Verzonden` → `"Verzonden"` in JSON.

## SlotverklaringController — OTP flow

```
1. POST /otp        → genereert 6-cijferig OTP
                    → slaat SHA256(otp + offerteId) op in _store (in-memory)
                    → retourneert otpMock in response (ALLEEN mock!)
2. POST /ondertekenen → verifieert OTP met timing-safe compare
                     → maakt HMAC-SHA256 audittrail
                     → retourneert OndertekeningBevestiging
```

**Productie**: gebruik bcrypt voor OTP hash, stuur OTP via email/SMS, sla op in database, gebruik eIDAS-gekwalificeerde handtekeningservice i.p.v. HMAC.

## VNAB Sanctieplatform

WSDL: `https://webservices.sanctieplatform.nl`
SOAP operations: `SearchPersonsByCriteria`, `GetOrganisationsByKvKNumber`, `CreateInvestigation`

VnabController is een REST proxy die SOAP calls wrappet. Mock retourneert 70% `Goedgekeurd` / 30% `HandmatigeReview`.

Credentials voor productie: GitHub Secrets `VNAB_USERNAME` + `VNAB_PASSWORD` (nog niet geconfigureerd).

## Environment variables (Railway)

```
ASPNETCORE_ENVIRONMENT=Production
Jwt__Secret=<geheim>
Jwt__Issuer=claeren-bff
Jwt__Audience=claeren-app
Features__MockCcs=true
```
