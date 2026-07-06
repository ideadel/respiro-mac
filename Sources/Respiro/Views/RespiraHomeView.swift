import SwiftUI

/// The narrative home: Mela breathing, an honest status line, one CTA and a
/// short timeline — not a grid of module launchers.
struct RespiraHomeView: View {
    @ObservedObject var junk: CleanupListViewModel
    @ObservedObject var trash: TrashViewModel
    @ObservedObject var protection: CleanupListViewModel
    @ObservedObject var startup: StartupViewModel
    @EnvironmentObject private var route: AppRoute

    @State private var isScanning = false
    @State private var hasScanned = false
    @State private var history = CleaningHistory()

    private var recoverable: Int64 { junk.totalSize + (trash.sizeBytes ?? 0) }

    private var status: BreathStatus {
        let stats = DiskUsageService.volumeStats()
        return BreathStatus.compute(
            freeBytes: stats?.free,
            totalBytes: stats?.total,
            recoverableBytes: hasScanned ? recoverable : nil,
            lastCleaning: history.records.last?.date
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            MelaMascot(size: 132, state: isScanning ? .scanning : (status.level == .bene && hasScanned ? .happy : .idle))

            VStack(spacing: 8) {
                Text(status.headline)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)
                Text(status.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
            }

            if isScanning {
                ProgressView().controlSize(.large)
            } else if hasScanned, recoverable > 0 {
                VStack(spacing: 10) {
                    Button("Rivedi e libera \(formatBytes(recoverable))") { route.open(.aria) }
                        .buttonStyle(.primaryCTA)
                        .keyboardShortcut(.defaultAction)
                    findingsRow
                }
            } else {
                Button("Fai un bel respiro") { Task { await runScan() } }
                    .buttonStyle(.primaryCTA)
                    .keyboardShortcut(.defaultAction)
            }

            timeline

            SystemVitalsView(onOpenTagliando: { route.open(.tagliando) })
                .padding(.top, 4)

            Spacer(minLength: 8)
            Text("Numeri veri: spazio reale misurato ora, mai stime gonfiate. Niente lascia il tuo Mac.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.windowPadding)
        .task {
            history = await CleaningHistoryStore.shared.history()
        }
    }

    /// Quiet links to what the scan found — not a launcher grid.
    private var findingsRow: some View {
        HStack(spacing: 16) {
            if junk.totalSize > 0 {
                findingLink("Aria: \(formatBytes(junk.totalSize))") { route.open(.aria) }
            }
            if let trashSize = trash.sizeBytes, trashSize > 0 {
                findingLink("Cestino: \(formatBytes(trashSize))") { route.open(.cestino) }
            }
            if !protection.items.isEmpty {
                findingLink("Guardia: \(protection.items.count) da controllare") { route.open(.guardia) }
            }
            if !startup.items.isEmpty {
                findingLink("Avvio: \(startup.items.count) elementi") { route.open(.avvio) }
            }
        }
    }

    private func findingLink(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Palette.accent)
    }

    @ViewBuilder
    private var timeline: some View {
        let recent = Array(history.records.suffix(5).reversed())
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Ultimi respiri")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Button("Vedi tutto") { route.open(.diario) }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.accent)
                }
                .padding(.horizontal, Metrics.cardPadding)
                .padding(.vertical, 10)
                Divider().overlay(Palette.border)
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, record in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.accent)
                        Text(Self.relativeDay(record.date))
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textSecondary)
                            .frame(width: 90, alignment: .leading)
                        Text(CleaningHistoryStore.displayName(forLabel: record.module))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text(formatBytes(record.bytesFreed) + " liberati")
                            .font(.system(size: 12))
                            .monospacedDigit()
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .padding(.horizontal, Metrics.cardPadding)
                    .padding(.vertical, 7)
                    if index < recent.count - 1 {
                        Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                    }
                }
            }
            .glassCard()
            .frame(maxWidth: 560)
        }
    }

    static func relativeDay(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func runScan() async {
        isScanning = true
        async let a: () = junk.scan()
        async let b: () = trash.refresh()
        async let c: () = protection.scan()
        async let d: () = startup.refresh()
        _ = await (a, b, c, d)
        isScanning = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { hasScanned = true }
    }
}
