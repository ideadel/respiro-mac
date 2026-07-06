import SwiftUI

struct UninstallerView: View {
    @StateObject private var appList = AppListViewModel()
    @StateObject private var reviewStore = UninstallerReviewStore()
    @State private var selectedApp: InstalledApp?
    @State private var catalogReady = false

    var body: some View {
        HSplitView {
            AppListView(viewModel: appList, selection: $selectedApp)
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)
            Group {
                if let app = selectedApp {
                    LeftoverDetailView(
                        app: app,
                        viewModel: reviewStore.viewModel(for: app.id),
                        allApps: appList.apps
                    ) {
                        let removedId = app.id
                        selectedApp = nil
                        reviewStore.discard(appId: removedId)
                        appList.removeApp(id: removedId)
                    }
                    .id(app.id)
                } else {
                    emptyState
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity)
        }
        .padding(Metrics.windowPadding)
        .task {
            await appList.scan()
            catalogReady = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if appList.isScanning && !catalogReady {
                MelaMascot(size: 64, state: .scanning)
                Text("Scansione app installate…")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
            } else {
                Image(systemName: Module.trasloco.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Palette.accent)
                Text("Seleziona un'app da disinstallare")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
