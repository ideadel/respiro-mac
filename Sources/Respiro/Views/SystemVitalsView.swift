import SwiftUI

/// Disk, RAM and CPU on Respira — with honest shortcuts to free memory.
struct SystemVitalsView: View {
    var onOpenTagliando: () -> Void = {}
    @State private var snapshot = SystemMetricsService.snapshot()
    @State private var isPurging = false
    @State private var purgeMessage: String?
    @State private var purgeSucceeded = false

    private var purgeTask: MaintenanceTask? { MaintenanceService.ramPurgeTask }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Vitali del Mac")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text("Aggiornato ora")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.horizontal, Metrics.cardPadding)
            .padding(.vertical, 10)
            Divider().overlay(Palette.border)
            HStack(spacing: 0) {
                vitalCell(
                    icon: "internaldrive",
                    title: "Disco",
                    value: diskLine,
                    detail: "Spazio libero sul volume di avvio"
                )
                Divider().overlay(Palette.border).frame(height: 44)
                vitalCell(
                    icon: "memorychip",
                    title: "RAM",
                    value: memoryLine,
                    detail: memoryDetail
                )
                Divider().overlay(Palette.border).frame(height: 44)
                vitalCell(
                    icon: "cpu",
                    title: "CPU",
                    value: cpuLine,
                    detail: "Carico medio (1 min), non un allarme"
                )
            }
            if purgeTask != nil {
                Divider().overlay(Palette.border)
                memoryShortcuts
            }
        }
        .glassCard()
        .frame(maxWidth: 560)
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
            refreshSnapshot()
        }
    }

    private var memoryShortcuts: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scorciatoie memoria")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Svuota la cache disco del kernel. Non è magia: libera cache, non chiude le app.")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let purgeMessage {
                    Text(purgeMessage)
                        .font(.system(size: 10))
                        .foregroundStyle(purgeSucceeded ? Palette.success : Palette.danger)
                }
            }
            Spacer(minLength: 8)
            if isPurging {
                ProgressView().controlSize(.small)
            } else if purgeSucceeded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.success)
            }
            Button {
                Task { await runPurge() }
            } label: {
                Label("Libera RAM", systemImage: "lock.fill")
            }
            .controlSize(.small)
            .disabled(isPurging)
            .help("Equivalente di «purge» — chiede la password amministratore.")
            Button("Tagliando") {
                onOpenTagliando()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Palette.accent)
            .help("Altri interventi di manutenzione")
        }
        .padding(.horizontal, Metrics.cardPadding)
        .padding(.vertical, 10)
    }

    private var diskLine: String {
        guard let free = snapshot.diskFree, let total = snapshot.diskTotal else {
            return "Non disponibile"
        }
        return "\(formatBytes(free)) liberi su \(formatBytes(total))"
    }

    private var memoryLine: String {
        guard let mem = snapshot.memory else { return "Non disponibile" }
        return "\(formatBytes(mem.availableBytes)) disponibili"
    }

    private var memoryDetail: String {
        guard let mem = snapshot.memory else { return "Lettura memoria non riuscita" }
        var parts = ["\(formatBytes(mem.totalBytes)) installati"]
        if mem.compressedBytes > 0 {
            parts.append("\(formatBytes(mem.compressedBytes)) compressi")
        }
        return parts.joined(separator: " · ")
    }

    private var cpuLine: String {
        guard let load = snapshot.cpuLoadPercent else { return "Non disponibile" }
        return String(format: "%.0f%% in uso", load)
    }

    private func vitalCell(icon: String, title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.textPrimary)
            Text(detail)
                .font(.system(size: 9))
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metrics.cardPadding)
        .padding(.vertical, 10)
        .help(detail)
    }

    private func refreshSnapshot() {
        snapshot = SystemMetricsService.snapshot()
    }

    @MainActor
    private func runPurge() async {
        guard let task = purgeTask else { return }
        isPurging = true
        purgeMessage = nil
        purgeSucceeded = false
        let service = MaintenanceService()
        do {
            try await service.run(task)
            purgeSucceeded = true
            purgeMessage = "Fatto. Controlla la RAM disponibile tra un attimo."
            refreshSnapshot()
            await ActionLogStore.shared.append([
                ActionRecord(date: Date(), module: "respira", path: task.id, bytes: 0,
                             action: "maintenanceTask", success: true)
            ])
        } catch {
            purgeSucceeded = false
            purgeMessage = error.localizedDescription
            await ActionLogStore.shared.append([
                ActionRecord(date: Date(), module: "respira", path: task.id, bytes: 0,
                             action: "maintenanceTask", success: false)
            ])
        }
        isPurging = false
    }
}
