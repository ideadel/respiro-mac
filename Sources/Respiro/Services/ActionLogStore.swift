import Foundation

/// One line per touched file: the heart of Respiro's radical transparency.
/// Append-only JSONL next to history.json — unbounded per-file entries would
/// bloat a single JSON array, a line-per-record file rotates cheaply.
struct ActionRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    /// Stable module key ("aria", "trasloco", …).
    let module: String
    let path: String
    let bytes: Int64
    /// trashed | deletedElevated | emptiedTrash | bootout | pkgForget | maintenanceTask
    let action: String
    let success: Bool
}

actor ActionLogStore {
    static let shared = ActionLogStore()
    private static let maxLines = 20_000

    private let fileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Respiro/actions.jsonl")

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func append(_ records: [ActionRecord]) {
        guard !records.isEmpty else { return }
        let lines = records.compactMap { record -> String? in
            guard let data = try? Self.encoder.encode(record) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        guard !lines.isEmpty else { return }
        let payload = lines.joined(separator: "\n") + "\n"
        let fm = FileManager.default
        try? fm.createDirectory(at: fileURL.deletingLastPathComponent(),
                                withIntermediateDirectories: true)
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: Data(payload.utf8))
        } else {
            try? Data(payload.utf8).write(to: fileURL, options: .atomic)
        }
        rotateIfNeeded()
    }

    func all() -> [ActionRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap {
            try? Self.decoder.decode(ActionRecord.self, from: Data($0.utf8))
        }
    }

    /// Export records as CSV or JSON, optionally limited to a date range.
    func exportData(asCSV: Bool, since: Date? = nil, until: Date? = nil) -> Data? {
        var records = all()
        if let since {
            records = records.filter { $0.date >= since }
        }
        if let until {
            records = records.filter { $0.date <= until }
        }
        if asCSV {
            let formatter = ISO8601DateFormatter()
            var csv = "data,modulo,percorso,byte,azione,esito\n"
            for record in records {
                let escapedPath = "\"" + record.path.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                csv += "\(formatter.string(from: record.date)),\(record.module),\(escapedPath),\(record.bytes),\(record.action),\(record.success ? "ok" : "fallito")\n"
            }
            return Data(csv.utf8)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(records)
    }

    private func rotateIfNeeded() {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else { return }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > Self.maxLines else { return }
        let kept = lines.suffix(Self.maxLines).joined(separator: "\n") + "\n"
        try? Data(kept.utf8).write(to: fileURL, options: .atomic)
    }
}

/// Convenience: build records from RemovalResults (the shape every removal
/// path already has in hand).
extension ActionLogStore {
    nonisolated static func records(module: String, action: String,
                                    results: [RemovalResult],
                                    sizes: [URL: Int64] = [:]) -> [ActionRecord] {
        results.map { result in
            ActionRecord(date: Date(), module: module, path: result.url.path,
                         bytes: sizes[result.url] ?? 0, action: action,
                         success: result.success)
        }
    }
}
