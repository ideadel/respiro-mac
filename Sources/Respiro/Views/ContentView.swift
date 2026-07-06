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
    @State private var isLicensed = LicenseService.isLicensed

    var body: some View {
        ZStack(alignment: .topLeading) {
            RespiroMainShell(
                junk: junkVM,
                largeFiles: largeFilesVM,
                duplicates: duplicatesVM,
                protection: protectionVM,
                trash: trashVM,
                startup: startupVM,
                maintenance: maintenanceVM,
                spaceLens: spaceLensVM
            )
            .environmentObject(route)
            if LicenseService.requiresLicense && !isLicensed {
                LicenseActivationView { isLicensed = true }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .respiroWindow()
    }
}

/// Shell layout — fixed chrome band on top, sidebar and content below.
private struct RespiroMainShell: View {
    @EnvironmentObject private var route: AppRoute
    @State private var revealed = false

    @ObservedObject var junk: CleanupListViewModel
    @ObservedObject var largeFiles: CleanupListViewModel
    @ObservedObject var duplicates: CleanupListViewModel
    @ObservedObject var protection: CleanupListViewModel
    @ObservedObject var trash: TrashViewModel
    @ObservedObject var startup: StartupViewModel
    @ObservedObject var maintenance: MaintenanceViewModel
    @ObservedObject var spaceLens: SpaceLensViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Aurora fills the whole window (behind the traffic lights).
            AuroraBackground(subdued: route.area != .respira)

            // Navigation chrome uses a fixed top inset and ignores the safe
            // area entirely: the safe area resolves 0 -> 32 over several frames
            // at launch, and reacting to it is exactly what made the sidebar
            // bounce. A constant inset over a size-bounded layout is stable
            // from the first frame.
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Metrics.chromeTopInset)
                    .accessibilityHidden(true)
                HStack(alignment: .top, spacing: 0) {
                    sidebar
                        .frame(width: 236)
                    Divider()
                        .overlay(Palette.border)
                    areaView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .clipped()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .ignoresSafeArea()
            // Reveal the chrome only after the first layout pass settles, so
            // the brief startup relayout is never visible.
            .opacity(revealed ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.18)) { revealed = true }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Area.allCases) { area in
                Button {
                    route.selectArea(area)
                } label: {
                    SidebarRow(area: area, isSelected: route.area == area)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.sidebarGlass.background(.ultraThinMaterial))
    }

    @ViewBuilder
    private var areaView: some View {
        let multiModule = route.area.modules.count > 1
        VStack(spacing: 0) {
            if multiModule {
                ModuleChipBar(modules: route.area.modules, selection: $route.module)
                    .padding(.horizontal, Metrics.windowPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: Metrics.chipBarBandHeight)
            }

            if route.module != .respira {
                ModuleContextBand(module: route.module, compact: multiModule)
                    .frame(height: multiModule ? Metrics.moduleContextCompactHeight : Metrics.moduleContextHeroHeight)
            }

            moduleView
                .moduleTitleHidden(true)
        }
    }

    @ViewBuilder
    private var moduleView: some View {
        switch route.module {
        case .respira:
            RespiraHomeView(junk: junk, trash: trash, protection: protection,
                            startup: startup)
        case .aria:
            CleanupModuleView(
                title: "Aria",
                subtitle: "Cache, log e file che le app ricreano da sole. Tutto finisce nel Cestino, recuperabile.",
                actionLabel: "Libera",
                emptyMessage: "Niente aria viziata: le cache sono già leggere.",
                reassurance: "Sono file rigenerabili: al massimo il primo avvio delle app sarà un filo più lento.",
                viewModel: junk)
        case .cestino:
            TrashView(viewModel: trash)
        case .zavorra:
            ZavorraView(largeFiles: largeFiles, duplicates: duplicates)
        case .panorama:
            SpaceLensView(viewModel: spaceLens)
        case .trasloco:
            UninstallerView()
        case .avvio:
            StartupView(viewModel: startup)
        case .tagliando:
            MaintenanceView(viewModel: maintenance)
        case .guardia:
            CleanupModuleView(
                title: "Guardia",
                subtitle: "Controllo degli elementi di avvio: eseguibili in posizioni sospette o nascosti. Non sostituisce un antivirus.",
                actionLabel: "Rimuovi selezionati",
                emptyMessage: "Nessuna anomalia trovata. Il tuo Mac è in ordine.",
                reassurance: "Nessun allarme: ti segnalo solo cose insolite da controllare.",
                viewModel: protection)
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
            SubModuleChipBar(titles: ["Ingombranti", "Doppioni"], selection: $tab)
            if tab == 0 {
                Text("File oltre 100 MB nelle cartelle utente. Nessuno è preselezionato.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metrics.windowPadding)
                    .padding(.bottom, 6)
                CleanupModuleView(
                    title: "Ingombranti",
                    subtitle: "",
                    actionLabel: "Sposta nel Cestino",
                    emptyMessage: "Nessun file oltre 100 MB nelle cartelle utente.",
                    reassurance: "Do solo un'occhiata: non tocco niente finché non scegli tu.",
                    viewModel: largeFiles)
            } else {
                Text("File identici (SHA-256) in Download, Documenti e Scrivania.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metrics.windowPadding)
                    .padding(.bottom, 6)
                CleanupModuleView(
                    title: "Doppioni",
                    subtitle: "",
                    actionLabel: "Rimuovi doppioni",
                    emptyMessage: "Nessun doppione trovato.",
                    reassurance: "Per ogni gruppo tengo una copia al sicuro.",
                    viewModel: duplicates)
            }
        }
    }
}

struct SidebarRow: View {
    let area: Area
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? area.selectedIcon : area.icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(area.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.textPrimary)
                Text(area.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: Metrics.sidebarRowHeight, maxHeight: Metrics.sidebarRowHeight, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Palette.accentTint : Color.clear)
        )
    }
}
