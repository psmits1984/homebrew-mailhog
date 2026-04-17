# TestFlight Setup — Stap voor stap

## Vereisten
- Mac met Xcode 15+
- Apple Developer account (€99/jaar) — https://developer.apple.com
- Flutter SDK geïnstalleerd — https://flutter.dev
- Ruby + Bundler (`gem install bundler`)

---

## Stap 1 — Flutter project genereren (eenmalig)

```bash
cd src/claeren_policy_app

# iOS project aanmaken (overschrijft niets in lib/)
flutter create --org nl.claeren --project-name claeren_policy_app .

# Dependencies ophalen
flutter pub get

# iOS pods installeren
cd ios && pod install && cd ..
```

---

## Stap 2 — Bundle ID instellen in Xcode

1. Open `src/claeren_policy_app/ios/Runner.xcworkspace` in Xcode
2. Klik op **Runner** (blauw icoon) → **Signing & Capabilities**
3. Stel in:
   - **Bundle Identifier**: `nl.claeren.policyapp`
   - **Team**: selecteer jouw Apple Developer team
   - **Automatically manage signing**: ✅ aan

---

## Stap 3 — App aanmaken in App Store Connect

1. Ga naar https://appstoreconnect.apple.com
2. **Apps** → **+** → **New App**
3. Vul in:
   - Platform: iOS
   - Name: `Claeren`
   - Bundle ID: `nl.claeren.policyapp`
   - SKU: `claeren-policy-app`
4. Sla op

---

## Stap 4 — App Store Connect API key (voor CI/CD)

1. Ga naar https://appstoreconnect.apple.com/access/integrations/api
2. **Generate API Key** → rol: **App Manager**
3. Download het `.p8` bestand (maar één keer downloadbaar!)
4. Noteer: **Key ID** en **Issuer ID**

Sla op als GitHub Secrets (zie Stap 7):
- `ASC_KEY_ID` = Key ID
- `ASC_ISSUER_ID` = Issuer ID
- `ASC_PRIVATE_KEY` = base64 van het .p8 bestand:
  ```bash
  base64 -i AuthKey_XXXXXX.p8 | pbcopy
  ```

---

## Stap 5 — Fastlane Match instellen (certificaten)

Match bewaart certificaten veilig in een aparte git-repo.

```bash
# Maak een lege privé git-repo aan, bijv. github.com/jouw-org/claeren-certificates

cd src/claeren_policy_app

# Match initialiseren
bundle exec fastlane match init
# → kies: git
# → vul de URL in van de certificates-repo

# Certificaten aanmaken voor App Store
bundle exec fastlane match appstore
```

Sla het Match wachtwoord op als GitHub Secret: `MATCH_PASSWORD`

---

## Stap 6 — Handmatig testen op iPhone (zonder CI)

```bash
cd src/claeren_policy_app

# Zorg dat de BFF draait op je Mac (mock modus):
cd ../../src/Claeren.PolicyApp.BFF && dotnet run &

# Verbind iPhone via USB, vertrouw de Mac op het toestel
flutter run --release \
  --dart-define=ENV=development \
  --dart-define=API_URL=http://192.168.1.XX:5000
```

---

## Stap 7 — GitHub Secrets instellen (voor automatische CI builds)

Ga naar: **GitHub repo** → **Settings** → **Secrets and variables** → **Actions**

| Secret | Waarde |
|--------|--------|
| `ASC_KEY_ID` | App Store Connect Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_PRIVATE_KEY` | base64 van .p8 bestand |
| `MATCH_GIT_TOKEN` | GitHub Personal Access Token voor certificates-repo |
| `MATCH_PASSWORD` | Wachtwoord voor Match certificaten versleuteling |

---

## Stap 8 — Eerste TestFlight build uitrollen

```bash
cd src/claeren_policy_app

# Handmatig via Fastlane:
bundle exec fastlane beta

# Of push naar main → GitHub Actions rolt automatisch uit
```

Na succesvolle upload:
1. Ga naar App Store Connect → TestFlight
2. Voeg interne testers toe (jij + collega's)
3. Testers ontvangen een uitnodiging per e-mail
4. Installeer **TestFlight** app op iPhone → accepteer uitnodiging → installeer Claeren

---

## Troubleshooting

**"No provisioning profile"**
→ `bundle exec fastlane match appstore --force`

**"Flutter build mislukt"**
→ `flutter clean && flutter pub get && cd ios && pod install`

**"Code signing error in Xcode"**
→ Xcode → Product → Clean Build Folder, dan opnieuw builden
