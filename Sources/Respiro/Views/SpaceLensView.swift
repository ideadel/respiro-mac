import SwiftUI

struct SpaceLensView: View {
    @ObservedObject var viewModel: SpaceLensViewModel

    var body: some View {
        VStack(spacing: 14) {
            header
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .scanning)
                    Text("Calcolo dimensioni di \(viewModel.currentDirectory.lastPathComponent)…")
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
            } else {
                entryList
            }
        }
        .padding(Metrics.windowPadding)
        .navigationTitle("Space Lens")
        .onAppear { viewModel.loadIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Space Lens").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.textPrimary)
                    if let stats = DiskUsageService.volumeStats() {
                        Text("Volume di avvio · \(formatBytes(stats.total - stats.free)) usati · \(formatBytes(stats.free)) liberi")
                            .font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer()
                Button {
                    viewModel.load()
                } label: {
                    Label("Aggiorna", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain).foregroundStyle(Palette.accent)
            }
            if let stats = DiskUsageService.volumeStats() {
                let used = Double(stats.total - stats.free)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.border)
                        Capsule().fill(Palette.accent)
                            .frame(width: proxy.size.width * used / Double(stats.total))
                    }
                }
                .frame(height: 8)
            }
            HStack {
                Button { viewModel.goUp() } label: { Image(systemName: "chevron.up") }
                    .buttonStyle(.plain).foregroundStyle(Palette.accent)
                    .disabled(!viewModel.canGoUp)
                Text(viewModel.currentDirectory.path)
                    .font(.system(size: 11)).foregroundStyle(Palette.textSecondary)
                    .lineLimit(1).truncationMode(.middle)
                Spacer()
            }
            if let message = viewModel.message {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.warning)
            }
        }
    }

    private var entryList: some View {
        let maxSize = viewModel.entries.first?.sizeBytes ?? 1
        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    SpaceLensRow(entry: entry, maxSize: maxSize, index: index) {
                        if entry.isDirectory { viewModel.load(entry.url) }
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
}

private struct SpaceLensRow: View {
    let entry: DiskEntry
    let maxSize: Int64
    let index: Int
    let onOpen: () -> Void
    var onTrash: () -> Void = {}
    @State private var progress: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                .foregroundStyle(entry.isDirectory ? Palette.accent : Palette.textSecondary)
            Text(entry.url.lastPathComponent).font(.system(size: 13)).foregroundStyle(Palette.textPrimary)
            Spacer()
            GeometryReader { proxy in
                Capsule().fill(Palette.accent.opacity(0.35))
                    .frame(width: max(3, proxy.size.width * progress), height: 10)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 160)
            Text(formatBytes(entry.sizeBytes)).font(.system(size: 12)).monospacedDigit()
                .foregroundStyle(Palette.textSecondary).frame(width: 82, alignment: .trailing)
        }
        .padding(.horizontal, Metrics.cardPadding)
        .frame(minHeight: Metrics.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onOpen)
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
    }
}
