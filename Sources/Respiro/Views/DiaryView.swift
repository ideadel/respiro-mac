import SwiftUI
import UniformTypeIdentifiers

/// Diario = Statistiche + Scia + Registro (per-file action log, exportable).
struct DiaryView: View {
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            SubModuleChipBar(titles: ["Statistiche", "Scia", "Registro"], selection: $tab)
            switch tab {
            case 0: StatsView()
            case 1: SciaView()
            default: ActionLogView()
            }
        }
    }
}

/// "Tutto quello che Respiro ha toccato, file per file. Niente è segreto."
struct ActionLogView: View {
    @State private var records: [ActionRecord] = []
    @State private var searchText = ""
    @State private var loaded = false
    @State private var exportMessage: String?

    private var filtered: [ActionRecord] {
        guard !searchText.isEmpty else { return records }
        let query = searchText.lowercased()
        return records.filter {
            $0.path.lowercased().contains(query)
                || CleaningHistoryStore.displayName(forLabel: $0.module).lowercased().contains(query)
        }
    }

    /// Newest first, grouped by calendar day.
    private var byDay: [(day: Date, records: [ActionRecord])] {
        let groups = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (day, (groups[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            if records.isEmpty && loaded {
                Spacer()
                VStack(spacing: 12) {
                    MelaMascot(size: 80, state: .idle)
                    Text("Il registro è ancora vuoto: comparirà qui ogni file toccato, con data, modulo e dimensione.")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }
                Spacer()
            } else {
                logList
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
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Cerca…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    Menu("Esporta") {
                        Button("CSV (Numbers/Excel)") { export(asCSV: true) }
                        Button("JSON") { export(asCSV: false) }
                    }
                    .frame(width: 90)
                }
                if let exportMessage {
                    Text(exportMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private var logList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(byDay, id: \.day) { day, dayRecords in
                    VStack(spacing: 0) {
                        HStack {
                            Text(Self.dayTitle(day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("\(dayRecords.count) azioni · \(formatBytes(dayRecords.map(\.bytes).reduce(0, +)))")
                                .font(.system(size: 12))
                                .monospacedDigit()
                                .foregroundStyle(Palette.textSecondary)
                        }
                        .padding(.horizontal, Metrics.cardPadding)
                        .padding(.vertical, 10)
                        Divider().overlay(Palette.border)
                        ForEach(Array(dayRecords.prefix(200).enumerated()), id: \.element.id) { index, record in
                            row(record)
                            if index < min(dayRecords.count, 200) - 1 {
                                Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                            }
                        }
                        if dayRecords.count > 200 {
                            Text("… e altre \(dayRecords.count - 200) azioni (usa Esporta per l'elenco completo)")
                                .font(.system(size: 11))
                                .foregroundStyle(Palette.textSecondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .glassCard()
                }
            }
        }
    }

    private func row(_ record: ActionRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(record.success ? Palette.success : Palette.danger)
            VStack(alignment: .leading, spacing: 1) {
                Text(URL(fileURLWithPath: record.path).lastPathComponent)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textPrimary)
                Text(record.path)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Text(CleaningHistoryStore.displayName(forLabel: record.module))
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Palette.accentTint, in: Capsule())
                .foregroundStyle(Palette.accent)
            Spacer()
            if record.bytes > 0 {
                Text(formatBytes(record.bytes))
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)
            }
            Text(record.date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, Metrics.cardPadding)
        .padding(.vertical, 6)
        .contextMenu {
            Button("Mostra nel Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: record.path)])
            }
        }
    }

    private func export(asCSV: Bool) {
        Task {
            guard let data = await ActionLogStore.shared.exportData(asCSV: asCSV) else {
                exportMessage = "Nessun dato da esportare."
                return
            }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [asCSV ? .commaSeparatedText : .json]
            panel.nameFieldStringValue = "registro-respiro." + (asCSV ? "csv" : "json")
            guard panel.runModal() == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url)
                exportMessage = "Esportato in \(url.lastPathComponent)."
            } catch {
                exportMessage = "Esportazione fallita: \(error.localizedDescription)"
            }
        }
    }

    static func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Oggi" }
        if Calendar.current.isDateInYesterday(day) { return "Ieri" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}
