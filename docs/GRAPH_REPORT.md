# Graph Report - .  (2026-07-04)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 552 nodes · 779 edges · 36 communities (33 shown, 3 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 29 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness

Snapshot generato dal commit `b0961103`. Rigenera con gli strumenti interni se la struttura cambia in modo rilevante.

## Community Hubs (Navigation)
- [[_COMMUNITY_Core Models & Routing|Core Models & Routing]]
- [[_COMMUNITY_Leftover Discovery Engine|Leftover Discovery Engine]]
- [[_COMMUNITY_Brand Mascot & Theme|Brand Mascot & Theme]]
- [[_COMMUNITY_Removal & Privilege Pipeline|Removal & Privilege Pipeline]]
- [[_COMMUNITY_Leftover Category Catalog|Leftover Category Catalog]]
- [[_COMMUNITY_Leftover Match Model|Leftover Match Model]]
- [[_COMMUNITY_Background Scan & Junk|Background Scan & Junk]]
- [[_COMMUNITY_Startup Trash & Updates|Startup Trash & Updates]]
- [[_COMMUNITY_Space Lens & Maintenance UI|Space Lens & Maintenance UI]]
- [[_COMMUNITY_Action Log & Protection Scan|Action Log & Protection Scan]]
- [[_COMMUNITY_Cleanup List ViewModel|Cleanup List ViewModel]]
- [[_COMMUNITY_Uninstaller Review Flow|Uninstaller Review Flow]]
- [[_COMMUNITY_Cleaning History Store|Cleaning History Store]]
- [[_COMMUNITY_Elevated Commands & Tagliando|Elevated Commands & Tagliando]]
- [[_COMMUNITY_Respira Home Dashboard|Respira Home Dashboard]]
- [[_COMMUNITY_Main Shell Navigation|Main Shell Navigation]]
- [[_COMMUNITY_Cleanup Module UI|Cleanup Module UI]]
- [[_COMMUNITY_Statistics Charts|Statistics Charts]]
- [[_COMMUNITY_Breath Status Narrative|Breath Status Narrative]]
- [[_COMMUNITY_Leftover Detail Panel|Leftover Detail Panel]]
- [[_COMMUNITY_Duplicate File Scanner|Duplicate File Scanner]]
- [[_COMMUNITY_File Size Calculator|File Size Calculator]]
- [[_COMMUNITY_Space Lens Visualization|Space Lens Visualization]]
- [[_COMMUNITY_Diary & Action Log UI|Diary & Action Log UI]]
- [[_COMMUNITY_App Entry & Menu Bar|App Entry & Menu Bar]]
- [[_COMMUNITY_Safety Deny List|Safety Deny List]]
- [[_COMMUNITY_Large Files Scanner|Large Files Scanner]]
- [[_COMMUNITY_Removal Confirmation Sheet|Removal Confirmation Sheet]]
- [[_COMMUNITY_App Bundle Inspection|App Bundle Inspection]]
- [[_COMMUNITY_Filesystem Search Roots|Filesystem Search Roots]]
- [[_COMMUNITY_Removal Results UI|Removal Results UI]]
- [[_COMMUNITY_Installed Apps List|Installed Apps List]]
- [[_COMMUNITY_User-Facing Explanations|User-Facing Explanations]]
- [[_COMMUNITY_Settings Screen|Settings Screen]]
- [[_COMMUNITY_Trash Empty Module|Trash Empty Module]]
- [[_COMMUNITY_Uninstaller Screen|Uninstaller Screen]]

## God Nodes (most connected - your core abstractions)
1. `LeftoverCategory` - 32 edges
2. `Module` - 19 edges
3. `CleanupListViewModel` - 14 edges
4. `LeftoverReviewViewModel` - 14 edges
5. `Area` - 13 edges
6. `SpaceLensViewModel` - 13 edges
7. `MatchReason` - 11 edges
8. `BackgroundScanScheduler` - 11 edges
9. `RespiraHomeView` - 11 edges
10. `LeftoverItem` - 10 edges

## Surprising Connections (you probably didn't know these)
- `RespiroApp` --implements--> `app`  [EXTRACTED]
  RespiroApp.swift → Models/Module.swift

## Import Cycles
- None detected.

## Communities (36 total, 3 thin omitted)

### Community 0 - "Core Models & Routing"
Cohesion: 0.05
Nodes (45): CaseIterable, Hashable, Identifiable, CleanableItem, formatBytes(), Bool, Int64, String (+37 more)

### Community 1 - "Leftover Discovery Engine"
Cohesion: 0.09
Nodes (20): LaunchdDomain, AppScanner, InstalledApp, LeftoverFinder, Bool, InstalledApp, LeftoverCategory, LeftoverItem (+12 more)

### Community 2 - "Brand Mascot & Theme"
Cohesion: 0.09
Nodes (23): ButtonStyle, CGRect, Color, Configuration, Path, Shape, MelaMascot, Smile (+15 more)

### Community 3 - "Removal & Privilege Pipeline"
Cohesion: 0.09
Nodes (23): LocalizedError, CleanupEngine, CleanableItem, RemovalResult, String, ElevatedRemovalOutcome, ElevationError, blockedBySafetyList (+15 more)

### Community 4 - "Leftover Category Catalog"
Cohesion: 0.07
Nodes (28): LeftoverCategory, applicationScripts, appSupport, audioPlugins, caches, containers, cookies, crashReports (+20 more)

### Community 5 - "Leftover Match Model"
Cohesion: 0.09
Nodes (24): Equatable, LaunchdDomain, system, userGui, LeftoverItem, LeftoverKind, file, packageReceipt (+16 more)

### Community 6 - "Background Scan & Junk"
Cohesion: 0.11
Nodes (13): NSRunningApplication, AppTerminator, Bool, String, BackgroundScanScheduler, Keys, Bool, Int64 (+5 more)

### Community 7 - "Startup Trash & Updates"
Cohesion: 0.09
Nodes (14): ObservableObject, Bool, UpdaterService, SPUStandardUpdaterController, AppListViewModel, InstalledApp, StartupViewModel, StartupItem (+6 more)

### Community 8 - "Space Lens & Maintenance UI"
Cohesion: 0.10
Nodes (15): MaintenanceViewModel, Never, Task, SpaceLensViewModel, Bool, DiskEntry, String, URL (+7 more)

### Community 9 - "Action Log & Protection Scan"
Cohesion: 0.13
Nodes (14): Data, JSONEncoder, ActionLogStore, ActionRecord, Bool, Date, Int64, JSONDecoder (+6 more)

### Community 10 - "Cleanup List ViewModel"
Cohesion: 0.15
Nodes (12): CleanupListViewModel, Phase, done, idle, removing, reviewing, scanning, Bool (+4 more)

### Community 11 - "Uninstaller Review Flow"
Cohesion: 0.16
Nodes (14): LeftoverReviewViewModel, Phase, done, loading, removing, reviewing, Bool, InstalledApp (+6 more)

### Community 12 - "Cleaning History Store"
Cohesion: 0.26
Nodes (11): Codable, CleaningHistory, CleaningHistoryStore, CleaningRecord, SpaceSnapshot, Date, Int, Int64 (+3 more)

### Community 13 - "Elevated Commands & Tagliando"
Cohesion: 0.20
Nodes (8): Int32, ElevatedCommandRunner, ProcessRunner, String, MaintenanceService, MaintenanceTask, Bool, String

### Community 14 - "Respira Home Dashboard"
Cohesion: 0.15
Nodes (10): AppRoute, BreathStatus, RespiraHomeView, CleanupListViewModel, Date, Int64, StartupViewModel, String (+2 more)

### Community 15 - "Main Shell Navigation"
Cohesion: 0.21
Nodes (10): Module, AuroraBackground, View, ContentView, ModuleChipBar, SidebarRow, Area, Bool (+2 more)

### Community 16 - "Cleanup Module UI"
Cohesion: 0.23
Nodes (9): CleanupModuleView, SpringCheckbox, Bool, CGFloat, CleanableItem, CleanupListViewModel, String, Void (+1 more)

### Community 17 - "Statistics Charts"
Cohesion: 0.24
Nodes (6): Content, View, StatsView, Date, Int64, String

### Community 18 - "Breath Status Narrative"
Cohesion: 0.22
Nodes (8): BreathStatus, Level, bene, corto, viziata, Date, Int64, String

### Community 19 - "Leftover Detail Panel"
Cohesion: 0.24
Nodes (7): LeftoverDetailView, InstalledApp, Int64, LeftoverCategory, LeftoverItem, String, Void

### Community 20 - "Duplicate File Scanner"
Cohesion: 0.42
Nodes (5): DuplicateScanner, CleanableItem, Int64, String, URL

### Community 21 - "File Size Calculator"
Cohesion: 0.36
Nodes (5): SizeCalculator, Int64, LeftoverItem, URL, UUID

### Community 22 - "Space Lens Visualization"
Cohesion: 0.22
Nodes (8): SpaceLensViewModel, SpaceLensRow, SpaceLensView, CGFloat, DiskEntry, Int, Int64, Void

### Community 23 - "Diary & Action Log UI"
Cohesion: 0.36
Nodes (5): ActionRecord, ActionLogView, DiaryView, Date, String

### Community 24 - "App Entry & Menu Bar"
Cohesion: 0.25
Nodes (6): app, NSImage, MenuBarLabel, MenuBarView, RespiroApp, Scene

### Community 25 - "Safety Deny List"
Cohesion: 0.43
Nodes (4): DenyList, Bool, String, URL

### Community 26 - "Large Files Scanner"
Cohesion: 0.48
Nodes (4): LargeFilesScanner, CleanableItem, Int64, URL

### Community 27 - "Removal Confirmation Sheet"
Cohesion: 0.29
Nodes (6): ConfirmRemovalSheet, Bool, Int, Int64, String, Void

### Community 28 - "App Bundle Inspection"
Cohesion: 0.33
Nodes (4): AppBundleInspector, InstalledApp, Set, String

### Community 29 - "Filesystem Search Roots"
Cohesion: 0.40
Nodes (5): SearchRoot, SearchRoots, Bool, LeftoverCategory, URL

### Community 30 - "Removal Results UI"
Cohesion: 0.33
Nodes (5): RemovalResultView, Bool, RemovalResult, String, Void

### Community 31 - "Installed Apps List"
Cohesion: 0.50
Nodes (3): AppListViewModel, AppListView, InstalledApp

### Community 32 - "User-Facing Explanations"
Cohesion: 0.50
Nodes (3): Explanations, LeftoverCategory, String

## Knowledge Gaps
- **201 isolated node(s):** `URL`, `Bool`, `String`, `URL`, `preferences` (+196 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report**

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Area` connect `Core Models & Routing` to `App Entry & Menu Bar`?**
  _High betweenness centrality (0.262) - this node is a cross-community bridge._
- **Why does `app` connect `App Entry & Menu Bar` to `Core Models & Routing`?**
  _High betweenness centrality (0.196) - this node is a cross-community bridge._
- **What connects `URL`, `Bool`, `String` to the rest of the system?**
  _201 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Core Models & Routing` be split into smaller, more focused modules?**
  _Cohesion score 0.05075187969924812 - nodes in this community are weakly interconnected._
- **Should `Leftover Discovery Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.0873440285204991 - nodes in this community are weakly interconnected._
- **Should `Brand Mascot & Theme` be split into smaller, more focused modules?**
  _Cohesion score 0.0907258064516129 - nodes in this community are weakly interconnected._
- **Should `Removal & Privilege Pipeline` be split into smaller, more focused modules?**
  _Cohesion score 0.08817204301075268 - nodes in this community are weakly interconnected._