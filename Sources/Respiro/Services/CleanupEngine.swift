import Foundation

/// Shared removal pipeline for the cleanup modules: normal items go to the
/// Trash directly, root-owned ones through a single admin prompt.
struct CleanupEngine {
    func remove(items: [CleanableItem]) async -> (results: [RemovalResult], banner: String?) {
        let plannedElevated = items.filter(\.requiresElevation)
        let normal = items.filter { !$0.requiresElevation }
        var results = await RemovalService().moveToTrash(urls: normal.map(\.url))
        var banner: String?

        let permissionRetries = results.filter {
            !$0.success && RemovalErrorMessage.isPermissionFailure($0.errorDescription)
        }
        let elevatedURLs = plannedElevated.map(\.url) + permissionRetries.map(\.url)

        if !elevatedURLs.isEmpty {
            do {
                let outcome = try await PrivilegedRemovalService().removeElevated(paths: elevatedURLs)
                results.removeAll { result in
                    permissionRetries.contains(where: { $0.url == result.url })
                }
                results += (plannedElevated.map(\.url) + permissionRetries.map(\.url)).map { url in
                    let removed = outcome.removedPaths.contains(url.path)
                    return RemovalResult(url: url, category: nil, success: removed,
                                         errorDescription: removed ? nil
                                         : "Non è stato possibile spostarlo nel Cestino, nemmeno con i privilegi di amministratore.")
                }
            } catch {
                if case ElevationError.userCancelled = error {
                    banner = "Rimozione con privilegi annullata — i file protetti non sono stati toccati."
                } else {
                    banner = error.localizedDescription
                }
                results.removeAll { result in
                    permissionRetries.contains(where: { $0.url == result.url })
                }
                results += elevatedURLs.map {
                    RemovalResult(url: $0, category: nil, success: false,
                                  errorDescription: error.localizedDescription)
                }
            }
        }
        return (results, banner)
    }
}
