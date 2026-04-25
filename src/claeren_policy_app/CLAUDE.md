# Flutter App — Claeren Policy App

## Stack

- Flutter 3.27, Dart, `useMaterial3: true`
- Renderer: **CanvasKit** (`--web-renderer canvaskit` in `web-deploy.yml`)
- State: Riverpod (`flutter_riverpod`)
- Routing: GoRouter (`go_router`)
- HTTP: Dio (`api_client.dart`)
- Storage: `flutter_secure_storage`
- i18n: Nederlands (NL)

## Kritieke patronen — LEES DIT EERST

### ✅ Enige werkende TextField aanpak op iOS Flutter Web (CanvasKit)

**Gebruik ALTIJD `Container(BoxDecoration)` + `TextField(filled:false, InputBorder.none)`.**
`TextFormField` / `OutlineInputBorder` / `filled:true` WERKT NIET — velden renderen grijs en het toetsenbord verschijnt niet.
`expands:true` en `InputDecoration.collapsed` ook NIET gebruiken.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: error != null ? AppColors.error : AppColors.divider,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    ),
    if (error != null)
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
      ),
  ],
)
```

### ✅ Dialogs en modals op iOS

- Gebruik **nooit** `showDialog` vanuit een `ListView`-context — dialog opent niet op iOS.
- Gebruik `showModalBottomSheet(useRootNavigator: true, ...)` voor bevestigingen.
- Gebruik `showDialog(useRootNavigator: true, ...)` voor foutmeldingen.
- Navigatiebevestigingen: ga direct door (geen bevestigingsdialog) en laat de volgende stap de confirmatie zijn.

### ✅ Knoppen en taps op iOS

- Gebruik **nooit** een `GestureDetector` wrapper om een `TextField` of `ElevatedButton`.
- `GestureDetector` op een handtekening-pad of custom container: gebruik `behavior: HitTestBehavior.opaque`.
- Prefereer `ElevatedButton` / `OutlinedButton` boven custom `GestureDetector`-knoppen.

### ✅ AppBar back-button

Altijd een **expliciete** leading opgeven in alle Scaffold-states (loading, error, data):

```dart
leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () => context.pop(),
),
```

Automatische leading (`automaticallyImplyLeading: true`) geeft een grijs vlak in CanvasKit op iOS.
Hoofdschermen met bottom nav: `automaticallyImplyLeading: false`.

## Bestandsstructuur

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart       # Alle API endpoints
│   │   ├── app_colors.dart          # Kleuren (primary=#8B7028 goud, background=#F5F0E5 crème)
│   │   ├── app_router.dart          # GoRouter configuratie
│   │   └── env.dart                 # API_URL dart-define
│   ├── network/api_client.dart      # Dio + JWT interceptor
│   ├── storage/secure_storage.dart  # Token opslag
│   ├── theme/app_theme.dart         # MaterialTheme (filled:true, fillColor:white)
│   └── widgets/app_bottom_nav.dart  # Persistent bottom nav (4 tabs)
└── features/
    ├── auth/          login, 2fa, onboarding
    ├── entity/        entiteitsselectie, profieldetail
    ├── policies/      polislijst, polisdetail
    ├── claims/        nieuwe schademelding
    ├── payments/      betaalbewijzen, SEPA-machtiging
    ├── naverrrekening naverrekeninguitvraag
    ├── offertes/      offertelijst, offertedetail (accorderen/weigeren)
    ├── compliance/    VNAB sanctiecontrole, UBO/CC formulier
    └── slotverklaring OTP-gebaseerde slotverklaring
```

## Routes (GoRouter — `app_router.dart`)

```
/auth/login
/auth/2fa                      extra: {sessionToken, requiresOnboarding}
/auth/onboarding               extra: sessionToken (String)
/entiteiten
/entiteiten/:entityId/profiel
/entiteiten/:entityId/betalingen
/entiteiten/:entityId/sepa     ?polis=&omschrijving=
/entiteiten/:entityId/offertes
/polissen/:entityId
/polissen/:entityId/:polisNummer
/polissen/:entityId/:polisNummer/claim
/naverrrekening/:entityId
/offertes/:offerteId
/offertes/:offerteId/compliance  extra: {entityId, relatieSoort, kvkNummer?}
/offertes/:offerteId/ubo         extra: {entityId}
/offertes/:offerteId/slotverklaring  extra: {entityId}
```

## Bottom Navigation (`app_bottom_nav.dart`)

Vier tabs: **Polissen** | **Offertes** | **Betalingen** | **Profiel**

Gebruik `BottomNavTab` enum + `AppBottomNav` widget in de `bottomNavigationBar` van het Scaffold.
Hoofdschermen met bottom nav gebruiken `automaticallyImplyLeading: false` in AppBar.

```dart
bottomNavigationBar: AppBottomNav(
  entityId: entityId,
  currentTab: BottomNavTab.polissen,  // of .offertes / .betalingen / .profiel
),
```

## Kleuren (`app_colors.dart`)

```dart
primary    = Color(0xFF8B7028)  // Donkergoud
accent     = Color(0xFFC9A535)  // Helder goud
background = Color(0xFFF5F0E5)  // Warm crème (scaffoldBackground)
surface    = Color(0xFFFFFFFF)  // Wit (kaarten, velden)
error      = Color(0xFFD32F2F)
success    = Color(0xFF2E7D32)
warning    = Color(0xFFF57C00)
textPrimary    = Color(0xFF1A1A2E)
textSecondary  = Color(0xFF6B7280)
divider        = Color(0xFFE5DEC8)
```

## Offerte flow

1. `OfferteListScreen` — lijst per entityId, gesorteerd op status (Nieuw / In behandeling / Afgerond)
2. `OfferteDetailScreen` — details + "Akkoord geven" (direct, geen dialog) / "Weigeren" (BottomSheet)
3. `ComplianceCheckScreen` — POST `/api/compliance/check` (VNAB sanctieplatform via BFF proxy)
   - Bij `Goedgekeurd` → door naar `SlotverklaringScreen`
   - Bij `HandmatigeReview` → door naar `UboFormulierScreen`
4. `UboFormulierScreen` — POST `/api/compliance/ubo`
5. `SlotverklaringScreen` — OTP genereren + invoeren + ondertekenen (AES eIDAS niveau)

## Bekende beperkingen (mock)

- BFF slaat geen state op: accorderen/weigeren reset na server restart
- VNAB: mock geeft 70% goedgekeurd / 30% handmatige review
- SlotverklaringController: OTP staat in response (`otpMock`) — alleen voor testen
- Documenten zijn niet echt downloadbaar (links verwijzen naar mock endpoints)
