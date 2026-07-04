import SwiftUI
import Charts

struct StatsView: View {
    @State private var history = CleaningHistory()
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryCards
                if history.records.isEmpty && history.snapshots.count < 2 {
                    emptyState
                } else {
                    if !recentDailyTotals.isEmpty { freedChart }
                    if history.snapshots.count >= 2 { freeSpaceChart }
                    if !moduleTotals.isEmpty { moduleBreakdown }
                }
            }
            .padding(Metrics.windowPadding)
        }
        .navigationTitle("Statistiche")
        .task {
            await CleaningHistoryStore.shared.snapshotFreeSpaceIfNeeded()
            history = await CleaningHistoryStore.shared.history()
            loaded = true
        }
    }

    // MARK: - Aggregations

    private var totalFreed: Int64 { history.records.map(\.bytesFreed).reduce(0, +) }

    private var freedLast30Days: Int64 {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return history.records.filter { $0.date >= cutoff }.map(\.bytesFreed).reduce(0, +)
    }

    /// (day, module) → bytes for the last 30 days.
    private var recentDailyTotals: [(day: Date, module: String, bytes: Int64)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var totals: [String: Int64] = [:]
        var keys: [String: (Date, String)] = [:]
        for record in history.records where record.date >= cutoff {
            let day = Calendar.current.startOfDay(for: record.date)
            let key = "\(day.timeIntervalSince1970)|\(record.module)"
            totals[key, default: 0] += record.bytesFreed
            keys[key] = (day, record.module)
        }
        return keys.compactMap { key, value in
            totals[key].map { (day: value.0, module: value.1, bytes: $0) }
        }.sorted { $0.day < $1.day }
    }

    private var moduleTotals: [(module: String, bytes: Int64)] {
        Dictionary(grouping: history.records, by: \.module)
            .map { (module: $0.key, bytes: $0.value.map(\.bytesFreed).reduce(0, +)) }
            .filter { $0.bytes > 0 }
            .sorted { $0.bytes > $1.bytes }
    }

    // MARK: - Sections

    private var summaryCards: some View {
        HStack(spacing: 14) {
            statCard(title: "Totale liberato", value: formatBytes(totalFreed), icon: "sparkles")
            statCard(title: "Ultimi 30 giorni", value: formatBytes(freedLast30Days), icon: "calendar")
            statCard(title: "Pulizie eseguite", value: "\(history.records.count)", icon: "checkmark.circle")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.cardPadding)
        .glassCard()
    }

    private var freedChart: some View {
        chartCard(title: "Spazio liberato al giorno (30 giorni)") {
            Chart(Array(recentDailyTotals.enumerated()), id: \.offset) { _, entry in
                BarMark(
                    x: .value("Giorno", entry.day, unit: .day),
                    y: .value("Liberato", Double(entry.bytes) / 1_000_000)
                )
                .foregroundStyle(by: .value("Modulo", entry.module))
                .cornerRadius(3)
            }
            .chartYAxisLabel("MB")
        }
    }

    private var freeSpaceChart: some View {
        chartCard(title: "Spazio libero sul volume") {
            Chart(Array(history.snapshots.enumerated()), id: \.offset) { _, snapshot in
                AreaMark(
                    x: .value("Data", snapshot.date),
                    y: .value("Liberi", Double(snapshot.freeBytes) / 1_000_000_000)
                )
                .foregroundStyle(Palette.accent.opacity(0.18))
                LineMark(
                    x: .value("Data", snapshot.date),
                    y: .value("Liberi", Double(snapshot.freeBytes) / 1_000_000_000)
                )
                .foregroundStyle(Palette.accent)
            }
            .chartYAxisLabel("GB")
        }
    }

    private var moduleBreakdown: some View {
        chartCard(title: "Ripartizione per modulo") {
            Chart(Array(moduleTotals.enumerated()), id: \.offset) { _, entry in
                BarMark(
                    x: .value("Liberato", Double(entry.bytes) / 1_000_000),
                    y: .value("Modulo", entry.module)
                )
                .foregroundStyle(Palette.accent)
                .cornerRadius(3)
            }
            .chartXAxisLabel("MB")
        }
    }

    private func chartCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            content()
                .frame(height: 180)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.cardPadding)
        .glassCard()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            MelaMascot(size: 80, state: .idle)
            Text("Ancora nessuna statistica: esegui la prima pulizia e qui vedrai lo spazio liberato nel tempo.")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
