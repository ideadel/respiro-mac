import Foundation

struct DiskEntry: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let sizeBytes: Int64
    let isDirectory: Bool
}

/// A mounted, browsable volume (boot disk, external drives, USB keys…).
struct VolumeInfo: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let name: String
    let isBootVolume: Bool
    let isInternal: Bool
    let free: Int64
    let total: Int64

    var icon: String { isInternal ? "internaldrive" : "externaldrive" }
}

/// Space Lens: per-directory size breakdown (view-only browser).
final class DiskUsageService {
    func entries(of directory: URL) async -> [DiskEntry] {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        return await withTaskGroup(of: DiskEntry.self) { group in
            for child in children {
                group.addTask {
                    let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    return DiskEntry(url: child,
                                     sizeBytes: SizeCalculator.recursiveSize(of: child),
                                     isDirectory: isDirectory)
                }
            }
            var entries: [DiskEntry] = []
            for await entry in group { entries.append(entry) }
            return entries.sorted { $0.sizeBytes > $1.sizeBytes }
        }
    }

    static func volumeStats(for volume: URL = URL(fileURLWithPath: "/")) -> (free: Int64, total: Int64)? {
        guard let values = try? volume.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey
        ]),
        let free = values.volumeAvailableCapacityForImportantUsage,
        let total = values.volumeTotalCapacity
        else { return nil }
        return (Int64(free), Int64(total))
    }

    /// All user-browsable volumes: the boot disk first, then external drives
    /// by name. Hidden and non-browsable mounts (snapshots, system helpers)
    /// are excluded.
    static func mountedVolumes() -> [VolumeInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeIsInternalKey, .volumeIsBrowsableKey,
            .volumeIsRootFileSystemKey,
            .volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey,
        ]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]
        ) ?? []
        var volumes: [VolumeInfo] = []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsBrowsable == true,
                  let total = values.volumeTotalCapacity, total > 0
            else { continue }
            let isRoot = values.volumeIsRootFileSystem ?? (url.path == "/")
            volumes.append(VolumeInfo(
                url: url,
                name: isRoot ? "Volume di avvio" : (values.volumeName ?? url.lastPathComponent),
                isBootVolume: isRoot,
                // Data volumes over network or unknown buses count as external.
                isInternal: values.volumeIsInternal ?? false,
                free: Int64(values.volumeAvailableCapacityForImportantUsage ?? 0),
                total: Int64(total)
            ))
        }
        return volumes.sorted {
            if $0.isBootVolume != $1.isBootVolume { return $0.isBootVolume }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
