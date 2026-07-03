import Foundation

@MainActor
final class SpaceLensViewModel: ObservableObject {
    @Published var currentDirectory = FileManager.default.homeDirectoryForCurrentUser
    @Published var entries: [DiskEntry] = []
    @Published var isLoading = false

    private let service = DiskUsageService()
    private var loadTask: Task<Void, Never>?

    func loadIfNeeded() {
        if entries.isEmpty && !isLoading { load() }
    }

    func load(_ directory: URL? = nil) {
        if let directory { currentDirectory = directory }
        loadTask?.cancel()
        isLoading = true
        entries = []
        let target = currentDirectory
        loadTask = Task {
            let result = await service.entries(of: target)
            guard !Task.isCancelled, target == currentDirectory else { return }
            entries = result
            isLoading = false
        }
    }

    var canGoUp: Bool { currentDirectory.pathComponents.count > 1 }

    func goUp() {
        guard canGoUp else { return }
        load(currentDirectory.deletingLastPathComponent())
    }
}
