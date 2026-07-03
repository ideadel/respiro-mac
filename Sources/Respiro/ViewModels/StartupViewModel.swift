import Foundation

@MainActor
final class StartupViewModel: ObservableObject {
    @Published var items: [StartupItem] = []
    @Published var isLoading = false
    @Published var banner: String?
    @Published var busyItemID: UUID?

    private let service = StartupItemsService()
    private let engine = CleanupEngine()

    func refreshIfNeeded() async {
        if items.isEmpty && !isLoading { await refresh() }
    }

    func refresh() async {
        isLoading = true
        items = await service.list()
        isLoading = false
    }

    func toggle(_ item: StartupItem) async {
        banner = nil
        busyItemID = item.id
        do {
            try await service.setDisabled(item, !item.isDisabled)
            await refresh()
        } catch {
            banner = error.localizedDescription
        }
        busyItemID = nil
    }

    func remove(_ item: StartupItem) async {
        banner = nil
        busyItemID = item.id
        let elevated = !FileManager.default.isDeletableFile(atPath: item.plistURL.path)
        let cleanable = CleanableItem(url: item.plistURL, group: "", requiresElevation: elevated)
        let (results, removalBanner) = await engine.remove(items: [cleanable])
        if let failure = results.first(where: { !$0.success }) {
            banner = failure.errorDescription
        } else if let removalBanner {
            banner = removalBanner
        }
        busyItemID = nil
        await refresh()
    }
}
