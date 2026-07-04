import Foundation

/// Keeps one review view model per app so switching back does not re-scan or blink.
@MainActor
final class UninstallerReviewStore: ObservableObject {
    private var cache: [String: LeftoverReviewViewModel] = [:]

    func viewModel(for appId: String) -> LeftoverReviewViewModel {
        if let existing = cache[appId] { return existing }
        let vm = LeftoverReviewViewModel()
        cache[appId] = vm
        return vm
    }

    func discard(appId: String) {
        cache.removeValue(forKey: appId)
    }
}
