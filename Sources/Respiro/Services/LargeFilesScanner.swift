import Foundation

/// Finds large files in the user content folders (Desktop, Documents,
/// Downloads, Movies, Music, Pictures, Public). Items start UNSELECTED —
/// the user opts in explicitly.
final class LargeFilesScanner {
    func scan(minSize: Int64 = 100 * 1024 * 1024,
              roots: [URL] = DenyList.userContentRoots) async -> [CleanableItem] {
        await Task.detached { Self.collect(minSize: minSize, roots: roots) }.value
    }

    private static func collect(minSize: Int64, roots: [URL]) -> [CleanableItem] {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey, .contentAccessDateKey]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var items: [CleanableItem] = []
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }
            for case let url as URL in enumerator {
                if Task.isCancelled { return items }
                guard let values = try? url.resourceValues(forKeys: Set(keys)),
                      values.isRegularFile == true,
                      let size = values.totalFileAllocatedSize,
                      Int64(size) >= minSize
                else { continue }
                let accessed = values.contentAccessDate.map {
                    "Ultimo accesso: \(dateFormatter.string(from: $0))"
                }
                items.append(CleanableItem(url: url, group: root.lastPathComponent,
                                           detail: accessed, sizeBytes: Int64(size),
                                           isSelected: false))
            }
        }
        return items.sorted { ($0.sizeBytes ?? 0) > ($1.sizeBytes ?? 0) }
    }
}
