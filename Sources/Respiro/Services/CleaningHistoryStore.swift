import Foundation

struct CleaningRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let module: String
    let bytesFreed: Int64
    let itemCount: Int
}

struct SpaceSnapshot: Codable {
    let date: Date
    let freeBytes: Int64
    let totalBytes: Int64
}

struct CleaningHistory: Codable {
    var records: [CleaningRecord] = []
    var snapshots: [SpaceSnapshot] = []
}

/// Persistent cleaning history feeding the Statistiche module. Plain JSON in
/// ~/Library/Application Support/Respiro — small, human-readable, no schema
/// migrations to worry about.
actor CleaningHistoryStore {
    static let shared = CleaningHistoryStore()

    private var cached: CleaningHistory?
    private let fileURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Respiro", isDirectory: true)
        return dir.appendingPathComponent("history.json")
    }()

    func history() -> CleaningHistory {
        if let cached { return cached }
        let loaded = (try? Data(contentsOf: fileURL))
            .flatMap { try? Self.decoder.decode(CleaningHistory.self, from: $0) }
            ?? CleaningHistory()
        cached = loaded
        return loaded
    }

    func record(module: String, bytesFreed: Int64, itemCount: Int) {
        guard bytesFreed > 0 || itemCount > 0 else { return }
        var history = history()
        history.records.append(CleaningRecord(date: Date(), module: module,
                                              bytesFreed: bytesFreed, itemCount: itemCount))
        save(history)
    }

    /// At most one snapshot every 6 hours, so the chart stays readable and
    /// the file small no matter how often the app is opened.
    func snapshotFreeSpaceIfNeeded() {
        guard let stats = DiskUsageService.volumeStats() else { return }
        var history = history()
        if let last = history.snapshots.last, Date().timeIntervalSince(last.date) < 6 * 3600 {
            return
        }
        history.snapshots.append(SpaceSnapshot(date: Date(), freeBytes: stats.free,
                                               totalBytes: stats.total))
        // Keep roughly a year of 6-hourly points.
        if history.snapshots.count > 1500 {
            history.snapshots.removeFirst(history.snapshots.count - 1500)
        }
        save(history)
    }

    private func save(_ history: CleaningHistory) {
        cached = history
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}

extension CleaningHistoryStore {
    /// JSONDecoder counterpart of the iso8601 encoding above.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
