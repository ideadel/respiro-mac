import SwiftUI

struct LeftoverDetailView: View {
    let app: InstalledApp
    var allApps: [InstalledApp] = []
    var onUninstalled: () -> Void

    @StateObject private var viewModel = LeftoverReviewViewModel()

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .scanning)
                    Text("Ricerca residui…")
                        .foregroundStyle(Palette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .reviewing, .removing:
                reviewContent
                    .disabled(viewModel.phase == .removing)
                    .overlay { removingOverlay }
            case .done:
                RemovalResultView(results: viewModel.results,
                                  banner: viewModel.errorBanner,
                                  appRemoved: viewModel.appRemoved,
                                  showLoginItemsNote: viewModel.hadLoginItemHints,
                                  onClose: onUninstalled)
            }
        }
        .navigationTitle(app.displayName)
        .task { await viewModel.load(app: app, allApps: allApps) }
        .sheet(isPresented: $viewModel.showConfirmSheet) {
            ConfirmRemovalSheet(
                appName: app.displayName,
                itemCount: viewModel.selectedItems.count,
                totalSize: viewModel.selectedSize,
                elevatedCount: viewModel.elevatedSelectedCount,
                receiptCount: viewModel.selectedReceiptCount,
                appIsRunning: viewModel.appIsRunning,
                onConfirm: {
                    viewModel.showConfirmSheet = false
                    Task { await viewModel.performRemoval(app: app) }
                },
                onCancel: { viewModel.showConfirmSheet = false }
            )
        }
        .alert("L'app è ancora in esecuzione", isPresented: $viewModel.showForceQuitAlert) {
            Button("Forza chiusura e disinstalla", role: .destructive) {
                Task { await viewModel.performRemoval(app: app, forceQuit: true) }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("\(app.displayName) non si è chiusa entro pochi secondi. Vuoi forzarne la chiusura e continuare la disinstallazione?")
        }
    }

    private var removingOverlay: some View {
        Group {
            if viewModel.phase == .removing {
                ZStack {
                    Palette.sidebarGlass.opacity(0.35)
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            MelaMascot(size: 36, state: .scanning)
                            ProgressView()
                            Text("Rimozione in corso…")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassCard()
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 14) {
            header
            if viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .happy)
                    Text("Nessun file residuo trovato. Verrà spostata nel Cestino solo l'app.")
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                itemList
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text("\(app.bundleIdentifier ?? "—")\(app.version.map { " · v\($0)" } ?? "")")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Button("Disinstalla…") { viewModel.showConfirmSheet = true }
                    .buttonStyle(.primaryCTA)
                    .keyboardShortcut(.defaultAction)
                Text("\(viewModel.selectedItems.count) elementi · \(Self.formatBytes(viewModel.selectedSize))")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var itemList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(groupedItems, id: \.0) { category, items in
                    VStack(spacing: 0) {
                        HStack {
                            Text(category.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            WhyBadge(text: category.explanation)
                            Spacer()
                            Text(formatBytes(items.compactMap(\.sizeBytes).reduce(0, +)))
                                .font(.system(size: 12))
                                .monospacedDigit()
                                .foregroundStyle(Palette.textSecondary)
                        }
                        .padding(.horizontal, Metrics.cardPadding)
                        .padding(.vertical, 10)
                        Divider().overlay(Palette.border)
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            itemRow(item)
                            if index < items.count - 1 {
                                Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                            }
                        }
                    }
                    .glassCard()
                }
            }
        }
    }

    private func itemRow(_ item: LeftoverItem) -> some View {
        HStack(spacing: 10) {
            SpringCheckbox(isOn: item.isSelected) { viewModel.toggleSelection(item) }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.url.lastPathComponent)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textPrimary)
                Text(item.url.path)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if !item.matchReason.isHighConfidence {
                Text(item.matchReason.badge)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Palette.warning.opacity(0.16), in: Capsule())
                    .foregroundStyle(Palette.warning)
            } else if item.matchReason == .helperBundleId {
                Text(item.matchReason.badge)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Palette.accent.opacity(0.16), in: Capsule())
                    .foregroundStyle(Palette.accent)
            }
            if item.requiresElevation {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Palette.textSecondary)
                    .help("Richiede privilegi di amministratore")
            }

            Spacer()

            if let size = item.sizeBytes {
                Text(Self.formatBytes(size))
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
                    .monospacedDigit()
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
    }

    private var groupedItems: [(LeftoverCategory, [LeftoverItem])] {
        Dictionary(grouping: viewModel.items, by: \.category)
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        Self.formatBytes(bytes)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
