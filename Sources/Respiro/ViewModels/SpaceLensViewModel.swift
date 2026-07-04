import Foundation

@MainActor
final class SpaceLensViewModel: ObservableObject {
    @Published var currentDirectory = FileManager.default.homeDirectoryForCurrentUser
    @Published var entries: [DiskEntry] = []
    @Published var isLoading = false
    @Published var message: String?

    private let service = DiskUsageService()
    private var loadTask: Task<Void, Never>?

    /// Space Lens browses the whole volume, so deletion gets its own guard
    /// instead of DenyList's search-root allowlist: only strict descendants
    /// of the user's home can be trashed, never the home or ~/Library roots.
    nonisolated static func canTrash(_ url: URL) -> Bool {
        if DenyList.isBlockedPath(url) { return false }
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let components = resolved.pathComponents
        let homeComponents = home.pathComponents
        guard components.count > homeComponents.count,
              Array(components.prefix(homeComponents.count)) == homeComponents
        else { return false }
        let library = home.appendingPathComponent("Library").standardizedFileURL
        return resolved != library
    }

    func moveToTrash(_ entry: DiskEntry) async {
        message = nil
        guard Self.canTrash(entry.url) else {
            message = "Per sicurezza Space Lens può cestinare solo elementi dentro la tua cartella Inizio."
            return
        }
        do {
            try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
            await CleaningHistoryStore.shared.record(module: "panorama",
                                                     bytesFreed: entry.sizeBytes, itemCount: 1)
            await ActionLogStore.shared.append([
                ActionRecord(date: Date(), module: "panorama", path: entry.url.path,
                             bytes: entry.sizeBytes, action: "trashed", success: true)
            ])
            entries.removeAll { $0.id == entry.id }
        } catch {
            message = "Impossibile spostare nel Cestino: \(error.localizedDescription)"
        }
    }

    func loadIfNeeded() {
        if entries.isEmpty && !isLoading { load() }
    }

    func load(_ directory: URL? = nil) {
        if let directory { currentDirectory = directory }
        loadTask?.cancel()
        isLoading = true
        entries = []
        let target = currentDirectory
        loadTask = Task {
            let result = await service.entries(of: target)
            guard !Task.isCancelled, target == currentDirectory else { return }
            entries = result
            isLoading = false
        }
    }

    var canGoUp: Bool { currentDirectory.pathComponents.count > 1 }

    func goUp() {
        guard canGoUp else { return }
        load(currentDirectory.deletingLastPathComponent())
    }
}
