import Foundation

/// Shared removal pipeline for the cleanup modules: normal items go to the
/// Trash directly, root-owned ones through a single admin prompt.
struct CleanupEngine {
    func remove(items: [CleanableItem]) async -> (results: [RemovalResult], banner: String?) {
        let normal = items.filter { !$0.requiresElevation }
        let elevated = items.filter(\.requiresElevation)
        var results = await RemovalService().moveToTrash(urls: normal.map(\.url))
        var banner: String?
        if !elevated.isEmpty {
            do {
                try await PrivilegedRemovalService().removeElevated(paths: elevated.map(\.url))
                results += elevated.map {
                    RemovalResult(url: $0.url, category: nil, success: true, errorDescription: nil)
                }
            } catch {
                if case ElevationError.userCancelled = error {
                    banner = "Rimozione con privilegi annullata — gli elementi di sistema non sono stati toccati."
                } else {
                    banner = error.localizedDescription
                }
                results += elevated.map {
                    RemovalResult(url: $0.url, category: nil, success: false,
                                  errorDescription: error.localizedDescription)
                }
            }
        }
        return (results, banner)
    }
}
