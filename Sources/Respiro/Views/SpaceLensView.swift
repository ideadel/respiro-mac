import SwiftUI

struct SpaceLensView: View {
    @ObservedObject var viewModel: SpaceLensViewModel
    @ObservedObject private var volumeStore = VolumeSelectionStore.shared

    var body: some View {
        VStack(spacing: 14) {
            header
            if !viewModel.isLoading, !viewModel.guidedHints.isEmpty {
                guidedStrip
            }
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .scanning)
                    Text("Calcolo dimensioni di \(viewModel.title(for: viewModel.currentDirectory))…")
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
            } else {
                entryList
            }
        }
        .padding(Metrics.windowPadding)
        .onAppear { viewModel.adopt(volumeStore.selected) }
        .onChange(of: volumeStore.selected?.url) { _ in
            viewModel.adopt(volumeStore.selected)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Button {
                    viewModel.goUp()
                } label: {
                    Label("Indietro", systemImage: "chevron.backward")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.canGoUp ? Palette.accent : Palette.textSecondary)
                .disabled(!viewModel.canGoUp)
                .keyboardShortcut("[", modifiers: [.command])
                .help("Torna alla cartella superiore")

                Spacer()
                Button {
                    volumeStore.refresh()
                    viewModel.load()
                } label: {
                    Label("Aggiorna", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain).foregroundStyle(Palette.accent)
            }
            if let volume = viewModel.selectedVolume {
                Text("\(volume.name) · \(formatBytes(volume.total - volume.free)) usati · \(formatBytes(volume.free)) liberi")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                let used = Double(volume.total - volume.free)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.border)
                        Capsule().fill(Palette.accent)
                            .frame(width: proxy.size.width * used / Double(max(volume.total, 1)))
                    }
                }
                .frame(height: 8)
            }
            breadcrumbRow
            if let message = viewModel.message {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.warning)
            }
        }
    }

    private var breadcrumbRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.offset) { index, url in
                    if index > 0 {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    let isCurrent = index == viewModel.breadcrumbs.count - 1
                    Button {
                        viewModel.goToBreadcrumb(url)
                    } label: {
                        Text(viewModel.title(for: url))
                            .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
                            .foregroundStyle(isCurrent ? Palette.textPrimary : Palette.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCurrent)
                }
            }
        }
    }

    private var guidedStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cosa si può togliere con calma")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Text("Niente allarmi: sono le cartelle più grandi che di solito si ricreano da sole, o i download da rivedere. Tu decidi.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.textSecondary)
            ForEach(viewModel.guidedHints) { entry in
                let advice = SpaceAdvice.classify(entry.url, isDirectory: entry.isDirectory)
                Button {
                    if entry.isDirectory { viewModel.open(entry.url) }
                } label: {
                    HStack(spacing: 8) {
                        SpaceAdviceBadge(advice: advice)
                        Text(entry.url.lastPathComponent)
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(formatBytes(entry.sizeBytes))
                            .font(.system(size: 11)).monospacedDigit()
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .help(advice.explanation)
            }
        }
        .padding(12)
        .glassCard()
    }

    private var entryList: some View {
        let maxSize = viewModel.entries.first?.sizeBytes ?? 1
        return ScrollView {
            VStack(spacing: 0) {
                if viewModel.canGoUp {
                    parentRow
                    if !viewModel.entries.isEmpty {
                        Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                    }
                }
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    SpaceLensRow(entry: entry, maxSize: maxSize, index: index) {
                        if entry.isDirectory { viewModel.open(entry.url) }
                    } onTrash: {
                        Task { await viewModel.moveToTrash(entry) }
                    }
                    if index < viewModel.entries.count - 1 {
                        Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                    }
                }
            }
            .glassCard()
        }
    }

    private var parentRow: some View {
        Button {
            viewModel.goUp()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(Palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cartella superiore")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Text(viewModel.title(for: viewModel.trail.last ?? viewModel.navigationRoot))
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Metrics.cardPadding)
            .frame(minHeight: Metrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SpaceAdviceBadge: View {
    let advice: SpaceAdvice

    var body: some View {
        Text(advice.label)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Palette.accentTint, in: Capsule())
            .foregroundStyle(Palette.accent)
    }
}

private struct SpaceLensRow: View {
    let entry: DiskEntry
    let maxSize: Int64
    let index: Int
    let onOpen: () -> Void
    var onTrash: () -> Void = {}
    @State private var progress: CGFloat = 0

    private var advice: SpaceAdvice {
        SpaceAdvice.classify(entry.url, isDirectory: entry.isDirectory)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                .foregroundStyle(entry.isDirectory ? Palette.accent : Palette.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.url.lastPathComponent).font(.system(size: 13)).foregroundStyle(Palette.textPrimary)
                if advice != .keep {
                    Text(advice.explanation)
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            if advice != .keep {
                SpaceAdviceBadge(advice: advice)
            }
            Spacer()
            GeometryReader { proxy in
                Capsule().fill(Palette.accent.opacity(0.35))
                    .frame(width: max(3, proxy.size.width * progress), height: 10)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 120)
            Text(formatBytes(entry.sizeBytes)).font(.system(size: 12)).monospacedDigit()
                .foregroundStyle(Palette.textSecondary).frame(width: 82, alignment: .trailing)
            if entry.isDirectory {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .onAppear {
            let target = CGFloat(entry.sizeBytes) / CGFloat(max(maxSize, 1))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.04)) {
                progress = target
            }
        }
        .contextMenu {
            Button("Mostra nel Finder") { NSWorkspace.shared.activateFileViewerSelecting([entry.url]) }
            if entry.isDirectory { Button("Apri qui", action: onOpen) }
            if SpaceLensViewModel.canTrash(entry.url) {
                Divider()
                Button("Sposta nel Cestino", role: .destructive, action: onTrash)
            }
        }
        .help(advice.explanation)
    }
}
