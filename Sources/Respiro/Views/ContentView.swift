import SwiftUI

struct ContentView: View {
    @State private var selection: Module? = .smartScan

    @StateObject private var junkVM = CleanupListViewModel { await JunkScanner().scan() }
    @StateObject private var largeFilesVM = CleanupListViewModel(computesSizes: false) {
        await LargeFilesScanner().scan()
    }
    @StateObject private var duplicatesVM = CleanupListViewModel(computesSizes: false) {
        await DuplicateScanner().scan()
    }
    @StateObject private var protectionVM = CleanupListViewModel(computesSizes: false) {
        await ProtectionScanner().scan()
    }
    @StateObject private var trashVM = TrashViewModel()
    @StateObject private var startupVM = StartupViewModel()
    @StateObject private var maintenanceVM = MaintenanceViewModel()
    @StateObject private var spaceLensVM = SpaceLensViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: Metrics.sidebarMin, ideal: 210)
        } detail: {
            detailView
                .background(AuroraBackground())
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(ModuleSection.all) { section in
                Section {
                    ForEach(section.modules) { module in
                        SidebarRow(module: module, isSelected: selection == module)
                            .tag(module)
                            .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text(section.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .tracking(0.6)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sidebarGlass.background(.ultraThinMaterial))
        .navigationTitle("Respiro")
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .smartScan {
        case .smartScan:
            SmartScanView(junk: junkVM, trash: trashVM, protection: protectionVM,
                          startup: startupVM, selection: $selection)
        case .systemJunk:
            CleanupModuleView(
                title: "Pulizia sistema",
                subtitle: "Cache, log, stato salvato, junk di Xcode e allegati Mail. Tutto finisce nel Cestino.",
                actionLabel: "Pulisci",
                emptyMessage: "Nessun file eliminabile trovato.",
                reassurance: "Ho controllato le cartelle di sistema: qui è tutto sicuro da rimuovere.",
                viewModel: junkVM)
        case .trash:
            TrashView(viewModel: trashVM)
        case .uninstaller:
            UninstallerView()
        case .startup:
            StartupView(viewModel: startupVM)
        case .maintenance:
            MaintenanceView(viewModel: maintenanceVM)
        case .largeFiles:
            CleanupModuleView(
                title: "File grandi",
                subtitle: "File oltre 100 MB nelle cartelle utente. Nessuno è preselezionato: scegli tu cosa spostare nel Cestino.",
                actionLabel: "Sposta nel Cestino",
                emptyMessage: "Nessun file oltre 100 MB nelle cartelle utente.",
                reassurance: "Do solo un'occhiata: non tocco niente finché non scegli tu.",
                viewModel: largeFilesVM)
        case .duplicates:
            CleanupModuleView(
                title: "Duplicati",
                subtitle: "File identici (verificati con hash SHA-256) in Download, Documenti e Scrivania. In ogni gruppo una copia resta protetta.",
                actionLabel: "Rimuovi duplicati",
                emptyMessage: "Nessun duplicato trovato.",
                reassurance: "Per ogni gruppo tengo una copia al sicuro.",
                viewModel: duplicatesVM)
        case .spaceLens:
            SpaceLensView(viewModel: spaceLensVM)
        case .protection:
            CleanupModuleView(
                title: "Protezione",
                subtitle: "Controllo euristico degli elementi di avvio: eseguibili in posizioni sospette o nascosti. Non sostituisce un antivirus.",
                actionLabel: "Rimuovi selezionati",
                emptyMessage: "Nessuna anomalia trovata. Il tuo Mac è in ordine.",
                reassurance: "Nessun allarme: ti segnalo solo cose insolite da controllare.",
                viewModel: protectionVM)
        }
    }
}

struct SidebarRow: View {
    let module: Module
    let isSelected: Bool

    var body: some View {
        Label {
            Text(module.title)
                .font(.system(size: 13, weight: .medium))
        } icon: {
            Image(systemName: isSelected ? module.selectedIcon : module.icon)
                .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
        }
        .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? Palette.accentTint : .clear)
        )
    }
}
