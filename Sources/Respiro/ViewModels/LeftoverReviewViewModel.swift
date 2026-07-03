import Foundation

@MainActor
final class LeftoverReviewViewModel: ObservableObject {
    enum Phase: Equatable {
        case loading, reviewing, removing, done
    }

    @Published var phase: Phase = .loading
    @Published var items: [LeftoverItem] = []
    @Published var results: [RemovalResult] = []
    @Published var appRemoved = false
    @Published var errorBanner: String?
    @Published var showConfirmSheet = false

    private let finder = LeftoverFinder()
    private let sizeCalculator = SizeCalculator()
    private let removalService = RemovalService()
    private let privilegedService = PrivilegedRemovalService()

    var selectedItems: [LeftoverItem] { items.filter(\.isSelected) }
    var selectedSize: Int64 { selectedItems.compactMap(\.sizeBytes).reduce(0, +) }
    var elevatedSelectedCount: Int { selectedItems.filter(\.requiresElevation).count }

    func load(app: InstalledApp) async {
        phase = .loading
        items = await finder.findLeftovers(for: app)
        phase = .reviewing
        let sizes = await sizeCalculator.totalSize(of: items)
        for index in items.indices {
            items[index].sizeBytes = sizes[items[index].id]
        }
    }

    func toggleSelection(_ item: LeftoverItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isSelected.toggle()
    }

    func performRemoval(app: InstalledApp) async {
        phase = .removing
        errorBanner = nil
        let selected = selectedItems
        let normal = selected.filter { !$0.requiresElevation }
        let elevated = selected.filter(\.requiresElevation)

        var allResults = await removalService.moveToTrash(normal)

        if !elevated.isEmpty {
            do {
                try await privilegedService.removeElevated(paths: elevated.map(\.url))
                allResults += elevated.map {
                    RemovalResult(url: $0.url, category: $0.category, success: true, errorDescription: nil)
                }
            } catch let error as ElevationError {
                if case .userCancelled = error {
                    errorBanner = "Rimozione con privilegi annullata — gli elementi di sistema non sono stati toccati."
                } else {
                    errorBanner = error.localizedDescription
                }
                allResults += elevated.map {
                    RemovalResult(url: $0.url, category: $0.category, success: false,
                                  errorDescription: error.localizedDescription)
                }
            } catch {
                errorBanner = error.localizedDescription
                allResults += elevated.map {
                    RemovalResult(url: $0.url, category: $0.category, success: false,
                                  errorDescription: error.localizedDescription)
                }
            }
        }

        do {
            try await removalService.moveAppToTrash(app)
            appRemoved = true
            allResults.append(RemovalResult(url: app.bundleURL, category: nil,
                                            success: true, errorDescription: nil))
        } catch {
            allResults.append(RemovalResult(url: app.bundleURL, category: nil,
                                            success: false,
                                            errorDescription: error.localizedDescription))
        }

        results = allResults
        phase = .done
    }
}
