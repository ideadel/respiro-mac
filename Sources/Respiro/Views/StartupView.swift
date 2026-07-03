import SwiftUI

struct StartupView: View {
    @ObservedObject var viewModel: StartupViewModel

    var body: some View {
        VStack(spacing: 14) {
            header
            if let banner = viewModel.banner {
                Text(banner)
                    .font(.callout)
                    .foregroundStyle(Palette.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metrics.cardPadding)
                    .padding(.vertical, 10)
                    .glassCard()
            }
            if viewModel.isLoading && viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .scanning)
                    Text("Lettura elementi di avvio…")
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
            } else if viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .happy)
                    Text("Nessun elemento di avvio di terze parti trovato.")
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
            } else {
                itemList
            }
        }
        .padding(Metrics.windowPadding)
        .navigationTitle("Avvio")
        .task { await viewModel.refreshIfNeeded() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Avvio")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text("LaunchAgents e LaunchDaemons di terze parti. Disattivali o rimuovili (nel Cestino).")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: 520, alignment: .leading)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Aggiorna", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
            .disabled(viewModel.isLoading)
        }
    }

    private var itemList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(StartupDomain.allCases, id: \.self) { domain in
                    let domainItems = viewModel.items.filter { $0.domain == domain }
                    if !domainItems.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text(domain.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.textPrimary)
                                Spacer()
                                Text("\(domainItems.count)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            .padding(.horizontal, Metrics.cardPadding)
                            .padding(.vertical, 10)
                            Divider().overlay(Palette.border)
                            ForEach(Array(domainItems.enumerated()), id: \.element.id) { index, item in
                                row(item)
                                if index < domainItems.count - 1 {
                                    Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                                }
                            }
                        }
                        .glassCard()
                    }
                }
            }
        }
    }

    private func row(_ item: StartupItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.label)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textPrimary)
                    if item.isDisabled {
                        Text("disattivato")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Palette.border, in: Capsule())
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Text(item.program ?? item.plistURL.path)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if item.requiresElevationToToggle {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Palette.textSecondary)
                    .help("Richiede privilegi di amministratore")
            }
            Spacer()
            if viewModel.busyItemID == item.id {
                ProgressView().controlSize(.small)
            } else {
                Button(item.isDisabled ? "Attiva" : "Disattiva") {
                    Task { await viewModel.toggle(item) }
                }
                .controlSize(.small)
                Button(role: .destructive) {
                    Task { await viewModel.remove(item) }
                } label: {
                    Image(systemName: "trash")
                }
                .controlSize(.small)
                .help("Sposta il plist nel Cestino")
            }
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
        .contextMenu {
            Button("Mostra nel Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.plistURL])
            }
        }
    }
}
