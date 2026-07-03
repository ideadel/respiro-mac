import Foundation

actor SizeCalculator {
    func totalSize(of items: [LeftoverItem]) async -> [UUID: Int64] {
        await withTaskGroup(of: (UUID, Int64).self) { group in
            for item in items {
                group.addTask { (item.id, Self.recursiveSize(of: item.url)) }
            }
            var results: [UUID: Int64] = [:]
            for await (id, size) in group { results[id] = size }
            return results
        }
    }

    func sizes(for urls: [URL]) async -> [URL: Int64] {
        await withTaskGroup(of: (URL, Int64).self) { group in
            for url in urls {
                group.addTask { (url, Self.recursiveSize(of: url)) }
            }
            var results: [URL: Int64] = [:]
            for await (url, size) in group { results[url] = size }
            return results
        }
    }

    nonisolated static func recursiveSize(of url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey]
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }
        if !isDirectory.boolValue {
            let values = try? url.resourceValues(forKeys: Set(keys))
            return Int64(values?.totalFileAllocatedSize ?? 0)
        }
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: keys, errorHandler: { _, _ in true }
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: Set(keys)), values.isDirectory != true {
                total += Int64(values.totalFileAllocatedSize ?? 0)
            }
        }
        return total
    }
}
