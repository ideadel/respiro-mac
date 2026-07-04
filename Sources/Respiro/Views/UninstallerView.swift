import SwiftUI

struct UninstallerView: View {
    @StateObject private var appList = AppListViewModel()
    @State private var selectedApp: InstalledApp?

    var body: some View {
        HSplitView {
            AppListView(viewModel: appList, selection: $selectedApp)
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)
            Group {
                if let app = selectedApp {
                    LeftoverDetailView(app: app, allApps: appList.apps) {
                        selectedApp = nil
                        Task { await appList.scan() }
                    }
                    .id(app.id)
                } else {
                    emptyState
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity)
        }
        .padding(Metrics.windowPadding)
        .navigationTitle("Trasloco")
        .task { await appList.scan() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: Module.trasloco.icon)
                .font(.system(size: 40))
                .foregroundStyle(Palette.accent)
            Text("Seleziona un'app da disinstallare")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
