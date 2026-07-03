import Foundation
import CryptoKit

/// Finds duplicate files (two-stage: group by size, confirm by full SHA-256).
/// In each group the first copy is kept unselected; the others default to
/// selected for removal (still Trash-recoverable).
final class DuplicateScanner {
    static let defaultRoots: [URL] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return ["Downloads", "Documents", "Desktop"].map {
            home.appendingPathComponent($0, isDirectory: true)
        }
    }()

    func scan(minSize: Int64 = 1024 * 1024,
              roots: [URL] = DuplicateScanner.defaultRoots) async -> [CleanableItem] {
        await Task.detached { Self.collect(minSize: minSize, roots: roots) }.value
    }

    private static func collect(minSize: Int64, roots: [URL]) -> [CleanableItem] {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey]
        var bySize: [Int64: [URL]] = [:]
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }
            for case let url as URL in enumerator {
                if Task.isCancelled { return [] }
                guard let values = try? url.resourceValues(forKeys: Set(keys)),
                      values.isRegularFile == true,
                      let size = values.fileSize.map(Int64.init),
                      size >= minSize
                else { continue }
                bySize[size, default: []].append(url)
            }
        }

        var items: [CleanableItem] = []
        for (size, urls) in bySize where urls.count > 1 {
            if Task.isCancelled { return items }
            var byHash: [String: [URL]] = [:]
            for url in urls {
                if let hash = Self.sha256(of: url) {
                    byHash[hash, default: []].append(url)
                }
            }
            for (_, duplicates) in byHash where duplicates.count > 1 {
                let sorted = duplicates.sorted { $0.path < $1.path }
                let group = "\(sorted[0].lastPathComponent) — \(duplicates.count) copie · \(formatBytes(size)) ciascuna"
                for (index, url) in sorted.enumerated() {
                    items.append(CleanableItem(url: url, group: group,
                                               detail: index == 0 ? "Copia da mantenere" : nil,
                                               sizeBytes: size,
                                               isSelected: index > 0))
                }
            }
        }
        return items
    }

    static func sha256(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
