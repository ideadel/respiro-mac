import AppKit

/// The disk being analyzed — the first discriminant of the Spazio area,
/// shared by every module that works per-volume (Panorama, Zavorra).
/// Reacts to drives being plugged in or ejected while the app runs.
@MainActor
final class VolumeSelectionStore: ObservableObject {
    static let shared = VolumeSelectionStore()

    @Published private(set) var volumes: [VolumeInfo] = []
    @Published var selected: VolumeInfo?

    private init() {
        refresh()
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    func refresh() {
        volumes = DiskUsageService.mountedVolumes()
        if let current = selected {
            selected = volumes.first { $0.url == current.url } ?? volumes.first
        } else {
            selected = volumes.first
        }
    }

    var isExternalSelected: Bool {
        guard let selected else { return false }
        return !selected.isBootVolume
    }

    /// Zavorra/Ingombranti roots: user content folders on the boot disk,
    /// the whole volume on an external drive.
    var largeFileRoots: [URL] {
        guard let selected, !selected.isBootVolume else { return DenyList.userContentRoots }
        return [selected.url]
    }

    /// Zavorra/Doppioni roots: same policy as above.
    var duplicateRoots: [URL] {
        guard let selected, !selected.isBootVolume else { return DuplicateScanner.defaultRoots }
        return [selected.url]
    }
}
