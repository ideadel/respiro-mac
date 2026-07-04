import SwiftUI
import UniformTypeIdentifiers

/// Timeline visiva delle azioni di Respiro — estensione del registro.
struct SciaView: View {
    enum Period: String, CaseIterable, Identifiable {
        case week = "7 giorni"
        case month = "30 giorni"
        case all = "Tutto"

        var id: String { rawValue }

        var startDate: Date? {
            let now = Date()
            switch self {
            case .week: return Calendar.current.date(byAdding: .day, value: -7, to: now)
            case .month: return Calendar.current.date(byAdding: .day, value: -30, to: now)
            case .all: return nil
            }
        }
    }

    @State private var records: [ActionRecord] = []
    @State private var period: Period = .month
    @State private var loaded = false
    @State private var exportMessage: String?

    private var filtered: [ActionRecord] {
        guard let start = period.startDate else { return records }
        return records.filter { $0.date >= start }
    }

    private var byDay: [(day: Date, modules: [(label: String, count: Int, bytes: Int64)])] {
        let groups = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            let dayRecords = groups[day] ?? []
            let moduleGroups = Dictionary(grouping: dayRecords, by: \.module)
            let modules = moduleGroups.keys.sorted().map { key in
                let items = moduleGroups[key] ?? []
                return (
                    label: CleaningHistoryStore.displayName(forLabel: key),
                    count: items.count,
                    bytes: items.map(\.bytes).reduce(0, +)
                )
            }
            return (day, modules)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            if filtered.isEmpty && loaded {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .idle)
                    Text("La scia è ancora vuota: ogni pulizia lascia una traccia reversibile qui.")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }
                Spacer()
            } else {
                timeline
            }
        }
        .padding(Metrics.windowPadding)
        .task {
            records = await ActionLogStore.shared.all()
            loaded = true
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scia")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text("La traccia di ciò che Respiro ha toccato — nel Cestino, recuperabile.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Picker("Periodo", selection: $period) {
                    ForEach(Period.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                Menu("Esporta periodo") {
                    Button("CSV") { export(asCSV: true) }
                    Button("JSON") { export(asCSV: false) }
                }
                if let exportMessage {
                    Text(exportMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private var timeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(byDay.enumerated()), id: \.element.day) { index, entry in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Palette.accent)
                                .frame(width: 10, height: 10)
                            if index < byDay.count - 1 {
                                Rectangle()
                                    .fill(Palette.border)
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 10)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(ActionLogView.dayTitle(entry.day))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            ForEach(entry.modules, id: \.label) { module in
                                HStack(spacing: 10) {
                                    Image(systemName: "wind")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Palette.accent)
                                    Text(module.label)
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Text("\(module.count) file · \(formatBytes(module.bytes))")
                                        .font(.system(size: 11))
                                        .monospacedDigit()
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Palette.accentTint.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
    }

    private func export(asCSV: Bool) {
        Task {
            guard let data = await ActionLogStore.shared.exportData(
                asCSV: asCSV, since: period.startDate, until: nil
            ) else {
                exportMessage = "Nessun dato nel periodo selezionato."
                return
            }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [asCSV ? .commaSeparatedText : .json]
            panel.nameFieldStringValue = "scia-respiro." + (asCSV ? "csv" : "json")
            guard panel.runModal() == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url)
                exportMessage = "Esportato in \(url.lastPathComponent)."
            } catch {
                exportMessage = "Esportazione fallita: \(error.localizedDescription)"
            }
        }
    }
}
