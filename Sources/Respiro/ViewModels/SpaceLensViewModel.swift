import Foundation

@MainActor
final class SpaceLensViewModel: ObservableObject {
    @Published var currentDirectory = FileManager.default.homeDirectoryForCurrentUser
    @Published var entries: [DiskEntry] = []
    @Published var isLoading = false
    @Published var message: String?
    @Published var selectedVolume: VolumeInfo?
    /// Cartelle da cui siamo scesi: serve per tornare indietro in modo affidabile.
    @Published private(set) var trail: [URL] = []

    private let service = DiskUsageService()
    private var loadTask: Task<Void, Never>?

    /// Space Lens browses whole volumes, so deletion gets its own guard
    /// instead of DenyList's search-root allowlist. Trashable: strict
    /// descendants of the user's home (never home itself or ~/Library), and
    /// strict descendants of non-boot volumes (never the mount point) —
    /// each external volume has its own per-volume Trash.
    nonisolated static func canTrash(_ url: URL) -> Bool {
        if DenyList.isBlockedPath(url) { return false }
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let components = resolved.pathComponents

        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let homeComponents = home.pathComponents
        if components.count > homeComponents.count,
           Array(components.prefix(homeComponents.count)) == homeComponents {
            let library = home.appendingPathComponent("Library").standardizedFileURL
            return resolved != library
        }

        // External/secondary volume: allowed below the mount point, but the
        // mount point itself and anything on the boot filesystem are not.
        guard let values = try? resolved.resourceValues(forKeys: [.volumeURLKey, .volumeIsRootFileSystemKey]),
              values.volumeIsRootFileSystem == false,
              let mountPoint = values.volume?.standardizedFileURL
        else { return false }
        return components.count > mountPoint.pathComponents.count
    }

    func moveToTrash(_ entry: DiskEntry) async {
        message = nil
        guard Self.canTrash(entry.url) else {
            message = "Per sicurezza Panorama può cestinare solo elementi dentro la tua cartella Inizio o su un disco esterno."
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

    /// Follows the shared VolumeBar selection: reloads when the volume
    /// actually changes (also covers ejection — the store falls back to the
    /// boot volume and this reloads accordingly).
    func adopt(_ volume: VolumeInfo?) {
        guard let volume else { return }
        if selectedVolume?.url != volume.url {
            selectedVolume = volume
            trail = []
            // The boot volume opens on the home folder (the interesting part
            // — the rest is mostly SIP-protected); external drives open at
            // the root.
            load(volume.isBootVolume ? FileManager.default.homeDirectoryForCurrentUser : volume.url)
        } else {
            selectedVolume = volume // refresh free/total numbers
            if entries.isEmpty && !isLoading { load() }
        }
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

    var navigationRoot: URL {
        if let volume = selectedVolume, !volume.isBootVolume {
            return volume.url.resolvingSymlinksInPath().standardizedFileURL
        }
        return FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
    }

    var canGoUp: Bool {
        !trail.isEmpty || Self.parent(of: currentDirectory, root: navigationRoot) != nil
    }

    var breadcrumbs: [URL] {
        trail + [currentDirectory]
    }

    /// Le voci più grandi che di solito si possono togliere senza perdere lavoro.
    var guidedHints: [DiskEntry] {
        entries
            .filter { SpaceAdvice.classify($0.url, isDirectory: $0.isDirectory) != .keep }
            .prefix(3)
            .map { $0 }
    }

    func open(_ url: URL) {
        let current = currentDirectory.standardizedFileURL
        let next = url.standardizedFileURL
        guard next != current else { return }
        trail.append(currentDirectory)
        load(url)
    }

    func goToBreadcrumb(_ url: URL) {
        let target = url.standardizedFileURL
        if let index = trail.firstIndex(where: { $0.standardizedFileURL == target }) {
            trail = Array(trail.prefix(index))
            load(url)
            return
        }
        if target == currentDirectory.standardizedFileURL { return }
        goUp()
    }

    func goUp() {
        if let previous = trail.popLast() {
            load(previous)
            return
        }
        guard let parent = Self.parent(of: currentDirectory, root: navigationRoot) else { return }
        load(parent)
    }

    func title(for url: URL) -> String {
        let standardized = url.standardizedFileURL
        if standardized == FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL {
            return "Inizio"
        }
        if let volume = selectedVolume, standardized == volume.url.standardizedFileURL {
            return volume.name
        }
        let name = url.lastPathComponent
        return name.isEmpty ? url.path : name
    }

    nonisolated static func parent(of url: URL, root: URL) -> URL? {
        let current = url.resolvingSymlinksInPath().standardizedFileURL
        let rootURL = root.resolvingSymlinksInPath().standardizedFileURL
        guard current.path != rootURL.path else { return nil }
        let parent = current.deletingLastPathComponent().standardizedFileURL
        if parent.path == rootURL.path { return parent }
        if parent.path.hasPrefix(rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/") {
            return parent
        }
        return nil
    }
}
