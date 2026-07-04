import SwiftUI

struct ContentView: View {
    @StateObject private var route = AppRoute()

    @StateObject private var junkVM = CleanupListViewModel(historyLabel: "aria") {
        await JunkScanner().scan()
    }
    @StateObject private var largeFilesVM = CleanupListViewModel(computesSizes: false,
                                                                 historyLabel: "zavorra") {
        await LargeFilesScanner().scan()
    }
    @StateObject private var duplicatesVM = CleanupListViewModel(computesSizes: false,
                                                                 historyLabel: "zavorra") {
        await DuplicateScanner().scan()
    }
    @StateObject private var protectionVM = CleanupListViewModel(computesSizes: false,
                                                                 historyLabel: "guardia") {
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
            areaView
                .background(AuroraBackground())
        }
        .frame(minWidth: 900, minHeight: 560)
        .environmentObject(route)
    }

    private var sidebar: some View {
        List(selection: Binding(
            get: { route.area },
            set: { newValue in route.selectArea(newValue ?? .respira) }
        ) as Binding<Area?>) {
            ForEach(Area.allCases) { area in
                SidebarRow(area: area, isSelected: route.area == area)
                    .tag(area)
                    .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.sidebarGlass.background(.ultraThinMaterial))
        .navigationTitle("Respiro")
    }

    @ViewBuilder
    private var areaView: some View {
        VStack(spacing: 0) {
            if route.area.modules.count > 1 {
                ModuleChipBar(modules: route.area.modules, selection: $route.module)
                    .padding(.horizontal, Metrics.windowPadding)
                    .padding(.top, 10)
            }
            moduleView
        }
    }

    @ViewBuilder
    private var moduleView: some View {
        switch route.module {
        case .respira:
            RespiraHomeView(junk: junkVM, trash: trashVM, protection: protectionVM,
                            startup: startupVM)
        case .aria:
            CleanupModuleView(
                title: "Aria",
                subtitle: "Cache, log e file che le app ricreano da sole. Tutto finisce nel Cestino, recuperabile.",
                actionLabel: "Libera",
                emptyMessage: "Niente aria viziata: le cache sono già leggere.",
                reassurance: "Sono file rigenerabili: al massimo il primo avvio delle app sarà un filo più lento.",
                viewModel: junkVM)
        case .cestino:
            TrashView(viewModel: trashVM)
        case .zavorra:
            ZavorraView(largeFiles: largeFilesVM, duplicates: duplicatesVM)
        case .panorama:
            SpaceLensView(viewModel: spaceLensVM)
        case .trasloco:
            UninstallerView()
        case .avvio:
            StartupView(viewModel: startupVM)
        case .tagliando:
            MaintenanceView(viewModel: maintenanceVM)
        case .guardia:
            CleanupModuleView(
                title: "Guardia",
                subtitle: "Controllo degli elementi di avvio: eseguibili in posizioni sospette o nascosti. Non sostituisce un antivirus.",
                actionLabel: "Rimuovi selezionati",
                emptyMessage: "Nessuna anomalia trovata. Il tuo Mac è in ordine.",
                reassurance: "Nessun allarme: ti segnalo solo cose insolite da controllare.",
                viewModel: protectionVM)
        case .diario:
            DiaryView()
        }
    }
}

/// Capsule segmented control switching modules inside an area.
struct ModuleChipBar: View {
    let modules: [Module]
    @Binding var selection: Module

    var body: some View {
        HStack(spacing: 8) {
            ForEach(modules) { module in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = module
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selection == module ? module.selectedIcon : module.icon)
                            .font(.system(size: 11))
                        Text(module.title)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selection == module ? Palette.accentTint : .clear)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(selection == module ? Palette.accent.opacity(0.4) : Palette.border,
                                          lineWidth: 1)
                    )
                    .foregroundStyle(selection == module ? Palette.accent : Palette.textSecondary)
                }
                .buttonStyle(.plain)
                .help(module.subtitle)
            }
            Spacer()
        }
    }
}

/// Zavorra: large files and duplicates as two tabs of one page.
struct ZavorraView: View {
    @ObservedObject var largeFiles: CleanupListViewModel
    @ObservedObject var duplicates: CleanupListViewModel
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("Ingombranti").tag(0)
                Text("Doppioni").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            .padding(.top, 12)
            if tab == 0 {
                CleanupModuleView(
                    title: "Ingombranti",
                    subtitle: "File oltre 100 MB nelle cartelle utente. Nessuno è preselezionato: scegli tu cosa spostare nel Cestino.",
                    actionLabel: "Sposta nel Cestino",
                    emptyMessage: "Nessun file oltre 100 MB nelle cartelle utente.",
                    reassurance: "Do solo un'occhiata: non tocco niente finché non scegli tu.",
                    viewModel: largeFiles)
            } else {
                CleanupModuleView(
                    title: "Doppioni",
                    subtitle: "File identici (verificati con hash SHA-256) in Download, Documenti e Scrivania. In ogni gruppo una copia resta protetta.",
                    actionLabel: "Rimuovi doppioni",
                    emptyMessage: "Nessun doppione trovato.",
                    reassurance: "Per ogni gruppo tengo una copia al sicuro.",
                    viewModel: duplicates)
            }
        }
        .navigationTitle("Zavorra")
    }
}

struct SidebarRow: View {
    let area: Area
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? area.selectedIcon : area.icon)
                .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(area.title)
                    .font(.system(size: 13, weight: .medium))
                Text(area.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Palette.accentTint : .clear)
        )
    }
}
