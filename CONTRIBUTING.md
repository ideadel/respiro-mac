# Contribuire a Respiro

Utility macOS (Swift/SwiftUI) per pulizia e manutenzione locale. Zero rete operativa, zero telemetria.

## Build

Richiede macOS 13+, SwiftPM e Command Line Tools (no Xcode):

```sh
./build-app.sh
open build/Respiro.app
```

Verifica automatica:

```sh
./scripts/verify.sh
```

Release (zip + checksum → portale):

```sh
./release.sh
```

## Vincoli non negoziabili

1. **Copy e UX** — rispetta `design/COPY-GUARDRAILS.md` (mai scare-marketing, mai rosso per junk, sempre reversibile).
2. **Lessico** — usa i nomi Respiro (`Aria`, `Trasloco`, `Panorama`…), mai i nomi CleanMyMac (`Smart Scan`, `Space Lens`…).
3. **Sicurezza** — ogni rimozione passa da `DenyList.validateForRemoval`; non bypassare.
4. **Registro** — ogni file toccato va in `ActionLogStore`.
5. **Scope** — il sito vive in `../sevenweb-portal/` (repo separato); modifiche al portale solo se legate alla release.

## Struttura sorgente

```
Sources/Respiro/
├── RespiroApp.swift       # @main, menu bar, settings, Sparkle
├── Models/                # Module, Area, CleanableItem, LeftoverItem…
├── Views/                 # SwiftUI per ogni modulo
├── ViewModels/            # stato e fasi di scan/rimozione
├── Services/              # scanner, rimozione, deny list, storico
└── Theme/                 # Palette, AuroraBackground, MelaMascot
```

## Moduli

| `Module` enum | UI | Scanner / servizio principale |
|---|---|---|
| `respira` | Home | `BreathStatus`, aggregati da altri VM |
| `aria` | Pulizia cache | `JunkScanner` |
| `cestino` | Svuota cestino | `TrashViewModel` |
| `zavorra` | Ingombranti + Doppioni | `LargeFilesScanner`, `DuplicateScanner` |
| `panorama` | Mappa disco | `SpaceLensViewModel`, `DiskUsageService` |
| `trasloco` | Disinstallatore | `AppScanner`, `LeftoverFinder`, `LeftoverReviewViewModel` |
| `avvio` | Login items | `StartupItemsService` |
| `tagliando` | Manutenzione | `MaintenanceService` |
| `guardia` | Avvio sospetto | `ProtectionScanner` |
| `diario` | Statistiche + registro | `CleaningHistoryStore`, `ActionLogStore` |

Navigazione: sidebar → `Area` (5 aree) → chip bar → `Module`. Stato in `AppRoute`.

## Come contribuire

1. **Fork** del repository
2. Crea un branch: `git checkout -b fix/trasloco-messaggio`
3. Modifica il codice rispettando i [guardrail di copy](design/COPY-GUARDRAILS.md)
4. Esegui `./scripts/verify.sh`
5. Apri una **Pull Request** verso `main` (template incluso)

Per cambiamenti grandi, apri prima una [Discussion](https://github.com/ideadel/respiro-mac/discussions) o un'issue.

## Wiki

Le pagine utente sono in [docs/wiki/](docs/wiki/). Per pubblicarle sulla GitHub Wiki:

```sh
./scripts/publish-wiki.sh
```

## Documentazione

| File | Contenuto |
|---|---|
| [docs/README.md](docs/README.md) | Indice |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layer, flussi, dipendenze |
| [docs/MODULES.md](docs/MODULES.md) | Moduli, view, view model |
| [docs/SERVICES.md](docs/SERVICES.md) | Servizi e responsabilità |
| [docs/QA-CHECKLIST.md](docs/QA-CHECKLIST.md) | Checklist manuale pre-release |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | Versioni e note portale |

## Licenza e distribuzione

- Codice: [MIT](LICENSE)
- Binario: scaricabile gratis da [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro)
- Sostegno opzionale: [Ko-fi](https://ko-fi.com/sevenwebtv)
