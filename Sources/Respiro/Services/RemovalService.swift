import Foundation

struct RemovalResult: Identifiable {
    let id = UUID()
    let url: URL
    let category: LeftoverCategory?
    let success: Bool
    let errorDescription: String?
}

struct RemovalError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct RemovalService {
    /// Moves user-owned items to the Trash (recoverable with "Put Back").
    func moveToTrash(_ items: [LeftoverItem]) async -> [RemovalResult] {
        var results: [RemovalResult] = []
        for item in items {
            guard DenyList.validateForRemoval(item.url) else {
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: false,
                                             errorDescription: "Bloccato dalla lista di sicurezza"))
                continue
            }
            do {
                try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: true, errorDescription: nil))
            } catch {
                results.append(RemovalResult(url: item.url, category: item.category,
                                             success: false,
                                             errorDescription: error.localizedDescription))
            }
        }
        return results
    }

    /// URL-based variant used by the cleanup modules.
    func moveToTrash(urls: [URL]) async -> [RemovalResult] {
        var results: [RemovalResult] = []
        for url in urls {
            guard DenyList.validateForRemoval(url) else {
                results.append(RemovalResult(url: url, category: nil, success: false,
                                             errorDescription: "Bloccato dalla lista di sicurezza"))
                continue
            }
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                results.append(RemovalResult(url: url, category: nil, success: true, errorDescription: nil))
            } catch {
                results.append(RemovalResult(url: url, category: nil, success: false,
                                             errorDescription: error.localizedDescription))
            }
        }
        return results
    }

    func moveAppToTrash(_ app: InstalledApp) async throws {
        guard !DenyList.isBlockedBundleId(app.bundleIdentifier),
              DenyList.validateForRemoval(app.bundleURL) else {
            throw RemovalError(message: "Bloccato dalla lista di sicurezza: \(app.bundleURL.path)")
        }
        try FileManager.default.trashItem(at: app.bundleURL, resultingItemURL: nil)
    }
}
