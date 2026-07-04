# Respiro — guida per agenti AI

Utility macOS (Swift/SwiftUI) per pulizia e manutenzione locale. Zero rete operativa, zero telemetria.

## Prima di esplorare il codice

Questo repo ha un **knowledge graph graphify** in `graphify-out/`.

```sh
graphify query "come funziona il disinstallatore?"
graphify path "UninstallerView" "LeftoverFinder"
graphify explain "CleanupEngine"
```

Dopo modifiche al codice Swift:

```sh
graphify update Sources/Respiro
```

Leggi `docs/README.md` per l'indice completo della documentazione.

## Vincoli non negoziabili

1. **Copy e UX** — rispetta `design/COPY-GUARDRAILS.md` (mai scare-marketing, mai rosso per junk, sempre reversibile).
2. **Lessico** — usa i nomi Respiro (`Aria`, `Trasloco`, `Panorama`…), mai i nomi CleanMyMac (`Smart Scan`, `Space Lens`…).
3. **Sicurezza** — ogni rimozione passa da `DenyList.validateForRemoval`; non bypassare.
4. **Registro** — ogni file toccato va in `ActionLogStore`.
5. **Scope** — non modificare `sevenweb-portal/` da questo repo (è gitignored, repo separato).

## Build e release

```sh
./build-app.sh          # build locale → build/Respiro.app
./release.sh            # zip + SHA256 → sevenweb-portal/public/downloads/respiro/
```

Richiede macOS 13+, SwiftPM, Command Line Tools (no Xcode). Sparkle per auto-update.

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

## Moduli (routing)

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

## Documentazione

| File | Contenuto |
|---|---|
| [docs/README.md](docs/README.md) | Indice |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layer, flussi, dipendenze |
| [docs/MODULES.md](docs/MODULES.md) | Moduli, view, view model |
| [docs/SERVICES.md](docs/SERVICES.md) | Servizi e responsabilità |
| [docs/GRAPHIFY.md](docs/GRAPHIFY.md) | Comandi graphify per questo repo |
| [docs/GRAPH_REPORT.md](docs/GRAPH_REPORT.md) | Report graphify (552 nodi, 36 community) |
| [design/COPY-GUARDRAILS.md](design/COPY-GUARDRAILS.md) | Regole copy/UX |

## Distribuzione

- Sito: [sevenweb.tv/apps/respiro](https://sevenweb.tv/apps/respiro)
- Versione: `Resources/Info.plist` → `CFBundleShortVersionString`
- Dati prodotto portale: `sevenweb-portal/public/data/respiro.json` (repo separato)
