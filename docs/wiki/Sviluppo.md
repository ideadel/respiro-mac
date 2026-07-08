# Sviluppo

## Prerequisiti

- macOS 13+
- Xcode Command Line Tools: `xcode-select --install`
- Git

## Build rapida

```sh
git clone https://github.com/ideadel/respiro-mac.git
cd respiro-mac
./build-app.sh
open build/Respiro.app
```

## Test automatici

```sh
./scripts/verify.sh
```

Esegue build release e self-test CLI (`--selftest-uninstaller`, denylist, cleanup, appscanner, systemextension).

## Struttura

```
Sources/Respiro/
├── Views/          # SwiftUI
├── ViewModels/     # stato moduli
├── Services/       # scanner, rimozione, deny list
├── Models/         # Module, Area, LeftoverItem…
└── Theme/          # palette, mascot
```

Documentazione tecnica:

- [ARCHITECTURE.md](https://github.com/ideadel/respiro-mac/blob/main/docs/ARCHITECTURE.md)
- [MODULES.md](https://github.com/ideadel/respiro-mac/blob/main/docs/MODULES.md)
- [SERVICES.md](https://github.com/ideadel/respiro-mac/blob/main/docs/SERVICES.md)

## Regole per le PR

1. Rispetta [COPY-GUARDRAILS.md](https://github.com/ideadel/respiro-mac/blob/main/design/COPY-GUARDRAILS.md)
2. Ogni rimozione: `DenyList.validateForRemoval` + `ActionLogStore`
3. `./scripts/verify.sh` deve passare
4. Niente telemetria o rete operativa

## Release (maintainer)

```sh
# Bump Resources/Info.plist
./release.sh
# Aggiorna ../sevenweb-portal/public/data/respiro.json
```

Vedi [QA-CHECKLIST.md](https://github.com/ideadel/respiro-mac/blob/main/docs/QA-CHECKLIST.md).

## CI

GitHub Actions esegue `verify.sh` su ogni push/PR verso `main` (`.github/workflows/ci.yml`).
