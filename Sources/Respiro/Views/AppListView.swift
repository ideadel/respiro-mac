import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: AppListViewModel
    @Binding var selection: InstalledApp?

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Cerca app", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accent)
                .disabled(viewModel.isScanning)
                .help("Aggiorna elenco app")
            }
            .padding(Metrics.cardPadding)
            .glassCard()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.filteredApps, id: \.id) { app in
                        appRow(app)
                        if app.id != viewModel.filteredApps.last?.id {
                            Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                        }
                    }
                }
                .glassCard()
            }
        }
        .overlay {
            if viewModel.isScanning && viewModel.apps.isEmpty {
                ProgressView("Scansione…")
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private func appRow(_ app: InstalledApp) -> some View {
        let isSelected = selection?.id == app.id
        return Button {
            selection = app
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(isSelected ? Palette.accent : Palette.textPrimary)
                    Text(app.bundleIdentifier ?? app.bundleURL.path)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, Metrics.cardPadding)
            .frame(minHeight: Metrics.rowHeight, alignment: .leading)
            .background(isSelected ? Palette.accentTint.opacity(0.5) : .clear)
        }
        .buttonStyle(.plain)
    }
}
