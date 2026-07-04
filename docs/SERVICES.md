# Servizi Respiro

Riferimento rapido per `Sources/Respiro/Services/`. Per dipendenze tra simboli usa `graphify explain "<Nome>"`.

## Scanner (producono `[CleanableItem]` o dati)

| Servizio | Modulo | Cosa scansiona |
|---|---|---|
| `JunkScanner` | Aria | Cache, log, file rigenerabili in `SearchRoots` junk |
| `LargeFilesScanner` | Zavorra | File > 100 MB in cartelle utente (`DenyList.userContentRoots`) |
| `DuplicateScanner` | Zavorra | Duplicati SHA-256 in Desktop/Documents/Downloads |
| `ProtectionScanner` | Guardia | Eseguibili in posizioni launch/login sospette |
| `AppScanner` | Trasloco | App in `/Applications` e `~/Applications` |
| `LeftoverFinder` | Trasloco | Residui post-disinstallazione (multi-root + euristica) |
| `DiskUsageService` | Panorama, menu bar | Statistiche volume, albero directory |

## Disinstallazione

| Servizio | Ruolo |
|---|---|
| `LeftoverFinder` | Trova residui per bundle ID, nome, vendor, receipt pkg |
| `AppBundleInspector` | Bundle ID ausiliari (helper, plugin) |
| `ReceiptService` | File da receipt `.pkg` |
| `SearchRoots` | Catalogo cartelle + categorie `LeftoverCategory` |
| `AppTerminator` | Termina processi app prima della rimozione |
| `SizeCalculator` | Dimensioni lazy su `LeftoverItem` |

## Rimozione

| Servizio | Ruolo |
|---|---|
| `CleanupEngine` | Orchestrazione: trash vs elevated |
| `RemovalService` | `FileManager.trashItem` con `DenyList` |
| `PrivilegedRemovalService` | Rimozione admin via `ElevatedCommandRunner` |
| `ElevatedCommandRunner` | Esecuzione comandi con privilegi |

## Sicurezza e spiegazioni

| Servizio | Ruolo |
|---|---|
| `DenyList` | Blocklist path/bundle; `validateForRemoval` |
| `Explanations` | Testo "Perché questo file?" per categoria |

## Manutenzione e avvio

| Servizio | Ruolo |
|---|---|
| `MaintenanceService` | Script manutenzione (cache DNS, log, ecc.) |
| `StartupItemsService` | Login items e agent launchd utente |

## Storico e stato

| Servizio | Ruolo |
|---|---|
| `ActionLogStore` | Registro file-by-file (JSON persistente) |
| `CleaningHistoryStore` | Snapshot spazio, record pulizie aggregate |
| `BreathStatus` | Narrativa home da numeri misurati |
| `BackgroundScanScheduler` | Scan periodico + notifica UNUserNotificationCenter |

## Aggiornamenti e test

| Servizio | Ruolo |
|---|---|
| `UpdaterService` | Wrapper Sparkle (`SPUStandardUpdaterController`) |
| `UninstallerSelfTest` | Test end-to-end disinstallatore (flag CLI) |

## Modelli correlati (`Models/`)

| Tipo | File | Note |
|---|---|---|
| `CleanableItem` | `CleanableItem.swift` | Item generico pulizia (url, size, elevation) |
| `LeftoverItem` | `LeftoverItem.swift` | Residuo disinstallazione + `MatchReason` |
| `LeftoverCategory` | in `LeftoverItem.swift` | caches, containers, preferences… |
| `InstalledApp` | `InstalledApp.swift` | App scansionata |
| `Module`, `Area` | `Module.swift` | Routing |

## ViewModels (`ViewModels/`)

| ViewModel | Usa servizi |
|---|---|
| `CleanupListViewModel` | Scanner generico + `CleanupEngine` |
| `LeftoverReviewViewModel` | `LeftoverFinder`, removal, `AppTerminator` |
| `AppListViewModel` | `AppScanner` |
| `TrashViewModel` | Trash diretto |
| `StartupViewModel` | `StartupItemsService` |
| `MaintenanceViewModel` | `MaintenanceService` |
| `SpaceLensViewModel` | `DiskUsageService` |

## Hook obbligatori per nuove rimozioni

1. `DenyList.validateForRemoval(url)` immediatamente prima dell'azione
2. `ActionLogStore.shared.record(...)` dopo successo
3. `CleaningHistoryStore` se modifica spazio recuperabile
4. Spiegazione in `Explanations` se nuova categoria junk

## Self-test

```sh
.build/release/Respiro --selftest-uninstaller
# oppure dopo build-app.sh:
build/Respiro.app/Contents/MacOS/Respiro --selftest-uninstaller
```

Exit 0 = pass, 1 = fail.
