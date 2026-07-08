# Architettura Respiro

Respiro è un'app macOS **non sandboxed** (firma ad-hoc) che opera interamente in locale. Lo stack è Swift 5.9 + SwiftUI, target macOS 13+, dipendenza esterna solo **Sparkle** per gli aggiornamenti.

## Layer

```
┌─────────────────────────────────────────────────────────┐
│  RespiroApp — WindowGroup, MenuBarExtra, Settings       │
│  ContentView — NavigationSplitView + routing moduli       │
└───────────────────────────┬─────────────────────────────┘
                            │ @StateObject / @EnvironmentObject
┌───────────────────────────▼─────────────────────────────┐
│  ViewModels — fasi (idle/scanning/reviewing/removing)   │
└───────────────────────────┬─────────────────────────────┘
                            │ async scan / remove
┌───────────────────────────▼─────────────────────────────┐
│  Services — scanner, CleanupEngine, DenyList, log      │
└───────────────────────────┬─────────────────────────────┘
                            │ FileManager, Process, admin
┌───────────────────────────▼─────────────────────────────┐
│  macOS — ~/Library, /Applications, launchd, Trash      │
└─────────────────────────────────────────────────────────┘
```

## Navigazione

Due livelli, definiti in `Models/Module.swift`:

1. **Sidebar** — seleziona `Area` (respira, spazio, app, energia, diario)
2. **Chip bar** — dentro ogni area con più moduli, seleziona `Module`

`AppRoute` (`@MainActor ObservableObject`) tiene `area` + `module` sincronizzati. Deep link e menu bar usano `route.open(_ module:)`.

`ContentView` istanzia tutti i ViewModel una volta e li passa alle view figlie (scan condivisi, niente re-scan al cambio tab).

## Pipeline di rimozione

Flusso comune per Aria, Zavorra, Guardia e moduli simili:

```
Scanner → [CleanableItem] → CleanupListViewModel (selezione utente)
    → ConfirmRemovalSheet → CleanupEngine.remove()
        → RemovalService.moveToTrash()     (utente)
        → PrivilegedRemovalService         (root / non deletable)
    → ActionLogStore (ogni path)
    → CleaningHistoryStore (aggregati per Diario)
```

**Regole di sicurezza:**

- `DenyList` blocca `/System`, `/Library/Apple`, bundle `com.apple.*`
- `validateForRemoval` verifica che il path sia discendente di una root consentita
- Controllo ripetuto **prima** di ogni rimozione (defense in depth)
- Default: **Cestino**, mai `rm` diretto

## Disinstallatore (Trasloco)

Percorso separato, più complesso:

```
AppScanner → [InstalledApp]
    → LeftoverFinder (SearchRoots + match euristici + ReceiptService)
    → LeftoverReviewViewModel (review, selezione, AppTerminator)
    → RemovalService / PrivilegedRemovalService + launchd unload
```

Self-test CLI: `Respiro --selftest-uninstaller` (esce prima della UI).

## Home (Respira)

`BreathStatus.compute()` deriva headline da:

- % spazio libero (`DiskUsageService`)
- byte recuperabili dall'ultima scan Aria
- giorni dall'ultima pulizia (`CleaningHistoryStore`)

Nessun numero gonfiato; stati: `bene`, `viziata`, `corto`.

## Background e menu bar

- `BackgroundScanScheduler` — Timer orario mentre l'app vive; notifica locale se junk > soglia
- `MenuBarExtra` — spazio libero + "Apri Respiro"
- `UpdaterService` — Sparkle (disattivo se framework/chiavi mancanti)

## Tema

- `Theme/Theme.swift` — `Palette`, `Metrics`, tipografia
- `AuroraBackground` — sfondo animato detail pane
- `MelaMascot` — mascot SVG-like in SwiftUI

## Build

| Script | Output |
|---|---|
| `build-app.sh` | `build/Respiro.app` — bundle Sparkle, icone, risorse |
| `release.sh` | `dist/Respiro-{version}-macOS-arm64.zip` + copia portale |

SwiftPM compila `Sources/Respiro`; risorse in `Sources/Respiro/Resources/`.

## Nodi centrali

Punti di ingresso utili per esplorare il codice:

1. `LeftoverCategory` — tassonomia residui disinstallazione
2. `Module` / `Area` — routing UI
3. `CleanupListViewModel` — pattern condiviso scan/rimozione
4. `LeftoverReviewViewModel` — disinstallatore
5. `BackgroundScanScheduler` — scan automatico

Vedi [GRAPH_REPORT.md](GRAPH_REPORT.md) per community e connessioni sorprendenti.

## Permessi macOS

- **Full Disk Access** consigliato per scan complete di `~/Library` e cartelle protette
- Prompt admin (`PrivilegedRemovalService`) solo per path non deletable dall'utente
- App **non** sandboxed per design (accesso filesystem reale)

## Cosa non toccare senza motivo

- `DenyList` — ogni allargamento è un rischio sicurezza
- `Explanations` — ogni nuova categoria junk richiede spiegazione utente
- Nomi `Module` / copy moduli — identità prodotto (vedi COPY-GUARDRAILS)
