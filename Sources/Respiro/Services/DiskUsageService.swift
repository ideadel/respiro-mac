import Foundation

struct DiskEntry: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let sizeBytes: Int64
    let isDirectory: Bool
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

    static func volumeStats() -> (free: Int64, total: Int64)? {
        let root = URL(fileURLWithPath: "/")
        guard let values = try? root.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey
        ]),
        let free = values.volumeAvailableCapacityForImportantUsage,
        let total = values.volumeTotalCapacity
        else { return nil }
        return (Int64(free), Int64(total))
    }
}
