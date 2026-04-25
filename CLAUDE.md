# Claeren Policy App — Project Gids

## Architectuur

```
homebrew-mailhog/
├── src/
│   ├── claeren_policy_app/          # Flutter Web + iOS app
│   └── Claeren.PolicyApp.BFF/       # .NET 8 Backend-for-Frontend (BFF)
├── .github/workflows/
│   ├── web-deploy.yml               # Flutter Web → GitHub Pages (trigger: push master)
│   ├── bff.yml                      # BFF Docker build + healthcheck (trigger: push master)
│   └── testflight.yml               # iOS TestFlight via Fastlane
└── CLAUDE.md                        # Dit bestand
```

## Deployment

| Component   | Platform        | URL                                                        | Trigger         |
|-------------|-----------------|-------------------------------------------------------------|-----------------|
| Flutter Web | GitHub Pages    | https://psmits1984.github.io/homebrew-mailhog/             | push naar master |
| BFF API     | Railway         | https://homebrew-mailhog-production.up.railway.app         | push naar master |
| iOS app     | TestFlight      | via Fastlane / `testflight.yml`                            | handmatig       |

**Na een push naar `master` duurt het 5–10 minuten voor de nieuwe versie live is.**

Flutter Web cached agressief via service worker. Na deploy: hard refresh in Safari (lang drukken ⟳ → "Herladen zonder cache").

## Git workflow

- Develop op `master` (triggers CI/CD automatisch)
- Feature branches: `claude/mobile-policy-app-kocRv` (merge naar master voor deploy)
- Push: `git push -u origin master`

## Testaccounts (mock)

| Email                  | Wachtwoord | Entities          |
|------------------------|------------|-------------------|
| zakelijk@claeren.nl    | Welkom02!  | ENT-001, ENT-002  |
| j.devries@claeren.nl   | Welkom01!  | ENT-003           |

## Deeldocumentatie

- [`src/claeren_policy_app/CLAUDE.md`](src/claeren_policy_app/CLAUDE.md) — Flutter app: patronen, routes, schermen
- [`src/Claeren.PolicyApp.BFF/CLAUDE.md`](src/Claeren.PolicyApp.BFF/CLAUDE.md) — BFF: endpoints, controllers, mock data
