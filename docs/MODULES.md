# Moduli Respiro

Mapping tra enum interni, UI utente e componenti Swift. I nomi **Respiro** sostituiscono il lessico CleanMyMac (vietato nel copy).

## Aree sidebar (`Area`)

| Area | Titolo UI | Moduli figli |
|---|---|---|
| `respira` | Respira | respira |
| `spazio` | Spazio | aria, cestino, zavorra, panorama |
| `app` | App | trasloco |
| `energia` | Energia | avvio, tagliando, guardia |
| `diario` | Diario | diario |

## Moduli (`Module`)

| Enum | Titolo | Sottotitolo | View | ViewModel / servizi |
|---|---|---|---|---|
| `respira` | Respira | Come sta il tuo Mac | `RespiraHomeView` | junk, trash, protection, startup VM |
| `aria` | Aria | Cache e file rigenerabili | `CleanupModuleView` | `CleanupListViewModel` + `JunkScanner` |
| `cestino` | Cestino | Svuota quando vuoi | `TrashView` | `TrashViewModel` |
| `zavorra` | Zavorra | File grandi e duplicati | `ZavorraView` → tab Ingombranti/Doppioni | `LargeFilesScanner`, `DuplicateScanner` |
| `panorama` | Panorama | Mappa dello spazio su disco | `SpaceLensView` | `SpaceLensViewModel` |
| `trasloco` | Trasloco | Disinstallazione profonda | `UninstallerView` | `AppListViewModel`, `LeftoverReviewViewModel` |
| `avvio` | Avvio | Elementi di login | `StartupView` | `StartupViewModel` |
| `tagliando` | Tagliando | Manutenzione periodica | `MaintenanceView` | `MaintenanceViewModel` |
| `guardia` | Guardia | Controlli di sicurezza | `CleanupModuleView` | `ProtectionScanner` |
| `diario` | Diario | Statistiche e registro | `DiaryView` | `StatsView`, `SciaView`, `ActionLogStore` |

## Menu bar (fuori da `Module`)

Definito in `RespiroApp.swift`:

- `MenuBarLabel` — glyph template `menubar-glyph.png`
- `MenuBarView` — spazio libero, apri app, esci

Non compare nella sidebar; equivalente portale: voce "Menu bar" in `respiro.json`.

## Pattern `CleanupModuleView`

Usato da Aria, Guardia e sotto-tab Zavorra. Parametri:

- `title`, `subtitle`, `actionLabel`, `emptyMessage`, `reassurance`
- `viewModel: CleanupListViewModel`

Fasi VM: `idle` → `scanning` → `reviewing` → `removing` → `done`.

Checkbox spring (`SpringCheckbox`); conferma in `ConfirmRemovalSheet`; risultati in `RemovalResultView`.

## Disinstallatore — view aggiuntive

| View | Ruolo |
|---|---|
| `AppListView` | Lista app installate |
| `LeftoverDetailView` | Dettaglio residui per app |
| `ConfirmRemovalSheet` | Conferma rimozione |

## Diario — sotto-sezioni

`DiaryView` combina:

- **Statistiche** — `StatsView` + `CleaningHistoryStore`
- **Registro** — `ActionLogView` / `ActionLogStore` (file per file)

## Alias marketing (solo portale / README)

Per compatibilità esterna (non nell'app):

| Nome esterno | Modulo Respiro |
|---|---|
| Smart Scan | respira (home) |
| Pulizia sistema | aria |
| File grandi | zavorra → Ingombranti |
| Duplicati | zavorra → Doppioni |
| Space Lens | panorama |
| Disinstallatore | trasloco |
| Manutenzione | tagliando |
| Protezione | guardia |

## Aggiungere un modulo

1. Aggiungi case a `Module` + `Area.modules` mapping
2. Crea o riusa View + ViewModel
3. Aggiungi branch in `ContentView.moduleView`
4. Se fa pulizia: scanner → `CleanableItem`, hook `ActionLogStore`, spiegazione in `Explanations`
5. Aggiorna `../sevenweb-portal/public/data/respiro.json` (repo portale)
6. `graphify update Sources/Respiro`
