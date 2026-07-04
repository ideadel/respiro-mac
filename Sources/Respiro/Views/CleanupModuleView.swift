import SwiftUI

/// Generic UI for the scan → review → Trash modules.
struct CleanupModuleView: View {
    let title: String
    let subtitle: String
    let actionLabel: String
    let emptyMessage: String
    var reassurance: String? = nil
    @ObservedObject var viewModel: CleanupListViewModel
    @State private var showConfirm = false

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .scanning:
                scanning
            case .reviewing:
                reviewContent
            case .removing:
                ProgressView("Rimozione in corso…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .done:
                doneView
            }
        }
        .navigationTitle(title)
        .task { await viewModel.scanIfNeeded() }
        .confirmationDialog(
            "Spostare nel Cestino \(viewModel.selectedItems.count) elementi (\(formatBytes(viewModel.selectedSize)))?",
            isPresented: $showConfirm, titleVisibility: .visible
        ) {
            Button(actionLabel, role: .destructive) {
                Task { await viewModel.performRemoval() }
            }
        }
    }

    private var scanning: some View {
        VStack(spacing: 16) {
            MelaMascot(size: 96, state: .scanning)
            Text("Analisi in corso…").foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewContent: some View {
        VStack(spacing: 14) {
            header
            if viewModel.items.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                itemList
                if let reassurance {
                    reassuranceBar(reassurance)
                }
            }
        }
        .padding(Metrics.windowPadding)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.textPrimary)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: 520, alignment: .leading)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Button("Tutto") { viewModel.setAllSelected(true) }.controlSize(.small)
                    Button("Niente") { viewModel.setAllSelected(false) }.controlSize(.small)
                    Button(actionLabel) { showConfirm = true }
                        .buttonStyle(.primaryCTA)
                        .disabled(viewModel.selectedItems.isEmpty)
                }
                Text("\(viewModel.selectedItems.count) su \(viewModel.items.count) · \(formatBytes(viewModel.selectedSize))")
                    .font(.system(size: 11)).monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)
                    .contentTransition(.numericText())
                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Label("Riesegui scansione", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain).font(.caption).foregroundStyle(Palette.accent)
            }
        }
    }

    private var itemList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(groups, id: \.0) { group, groupItems in
                    VStack(spacing: 0) {
                        HStack {
                            Text(group).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.textPrimary)
                            if let explanation = Explanations.explanation(forJunkGroup: group) {
                                WhyBadge(text: explanation)
                            }
                            Spacer()
                            Text(formatBytes(groupItems.compactMap(\.sizeBytes).reduce(0, +)))
                                .font(.system(size: 12)).monospacedDigit().foregroundStyle(Palette.textSecondary)
                        }
                        .padding(.horizontal, Metrics.cardPadding)
                        .padding(.vertical, 10)
                        Divider().overlay(Palette.border)
                        ForEach(Array(groupItems.enumerated()), id: \.element.id) { index, item in
                            itemRow(item)
                            if index < groupItems.count - 1 {
                                Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                            }
                        }
                    }
                    .glassCard()
                }
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: CleanableItem) -> some View {
        let isKeep = item.detail == "Copia da mantenere"
        HStack(spacing: 10) {
            if isKeep {
                Label("Tieni", systemImage: "pin.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 18)
            } else {
                SpringCheckbox(isOn: item.isSelected) { viewModel.toggle(item) }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.url.lastPathComponent)
                    .font(.system(size: 13)).foregroundStyle(Palette.textPrimary)
                Text(isKeep ? "Copia protetta" : (item.detail ?? item.url.path))
                    .font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
                    .lineLimit(1).truncationMode(.middle)
            }

            if isKeep {
                Text("Tieni")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Palette.accentTint, in: Capsule())
                    .foregroundStyle(Palette.accent)
            }
            if item.requiresElevation {
                Image(systemName: "lock.fill").foregroundStyle(Palette.textSecondary)
                    .help("Richiede privilegi di amministratore")
            }

            Spacer()

            if let size = item.sizeBytes {
                Text(formatBytes(size)).font(.system(size: 12)).monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
        .background(isKeep ? Palette.accentTint.opacity(0.5) : .clear)
        .contextMenu {
            Button("Mostra nel Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
    }

    private func reassuranceBar(_ text: String) -> some View {
        HStack(spacing: 10) {
            MelaMascot(size: 26, state: .idle)
            Text(text).font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            MelaMascot(size: 80, state: .happy)
            Text(emptyMessage).foregroundStyle(Palette.textSecondary)
        }
    }

    private var groups: [(String, [CleanableItem])] {
        var order: [String] = []
        var map: [String: [CleanableItem]] = [:]
        for item in viewModel.items {
            if map[item.group] == nil { order.append(item.group) }
            map[item.group, default: []].append(item)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private var doneView: some View {
        let failed = viewModel.results.filter { !$0.success }
        return VStack(spacing: 14) {
            MelaMascot(size: 96, state: .happy)
            Text(failed.isEmpty ? "Pulizia completata" : "Pulizia parziale")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(failed.isEmpty ? Palette.success : Palette.warning)
            Text("\(viewModel.results.filter(\.success).count) elementi spostati nel Cestino"
                 + (failed.isEmpty ? "" : " · \(failed.count) non rimossi"))
                .foregroundStyle(Palette.textSecondary)
            if let banner = viewModel.banner {
                Text(banner).font(.callout).foregroundStyle(Palette.warning)
            }
            if !failed.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(failed) { result in
                            VStack(alignment: .leading) {
                                Text(result.url.lastPathComponent).font(.system(size: 13))
                                if let error = result.errorDescription {
                                    Text(error).font(.caption).foregroundStyle(Palette.danger)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Metrics.cardPadding).padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .glassCard()
            }
            Button("OK") { Task { await viewModel.scan() } }
                .buttonStyle(.primaryCTA)
        }
        .padding(Metrics.windowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// ⓘ "Perché questo file?" — popover with the honest explanation of what a
/// category is and what happens if it goes.
struct WhyBadge: View {
    let text: String
    @State private var showing = false

    var body: some View {
        Button {
            showing.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundStyle(Palette.textSecondary)
        }
        .buttonStyle(.plain)
        .help("Perché questo file?")
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Perché questo file?")
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 300)
        }
    }
}

/// Checkbox with a spring scale bounce on toggle (0.8 → 1).
struct SpringCheckbox: View {
    let isOn: Bool
    let toggle: () -> Void
    @State private var scale: CGFloat = 1

    var body: some View {
        Button {
            toggle()
            scale = 0.8
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { scale = 1 }
        } label: {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(isOn ? Palette.accent : Palette.textSecondary)
                .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}
