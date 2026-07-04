import Foundation

/// Shared view model for every "scan → review with checkboxes → move to
/// Trash" module (system junk, large files, duplicates, protection).
@MainActor
final class CleanupListViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle, scanning, reviewing, removing, done
    }

    @Published var phase: Phase = .idle
    @Published var items: [CleanableItem] = []
    @Published var results: [RemovalResult] = []
    @Published var banner: String?

    private let scanner: () async -> [CleanableItem]
    private let computesSizes: Bool
    /// Module name recorded in the cleaning history (nil = don't record).
    private let historyLabel: String?
    private let engine = CleanupEngine()
    private let sizeCalculator = SizeCalculator()

    init(computesSizes: Bool = true, historyLabel: String? = nil,
         scanner: @escaping () async -> [CleanableItem]) {
        self.computesSizes = computesSizes
        self.historyLabel = historyLabel
        self.scanner = scanner
    }

    var selectedItems: [CleanableItem] { items.filter(\.isSelected) }
    var selectedSize: Int64 { selectedItems.compactMap(\.sizeBytes).reduce(0, +) }
    var totalSize: Int64 { items.compactMap(\.sizeBytes).reduce(0, +) }

    func scanIfNeeded() async {
        if phase == .idle { await scan() }
    }

    func scan() async {
        phase = .scanning
        banner = nil
        items = await scanner()
        phase = .reviewing
        if computesSizes {
            let sizes = await sizeCalculator.sizes(for: items.map(\.url))
            for index in items.indices {
                items[index].sizeBytes = sizes[items[index].url]
            }
        }
    }

    func toggle(_ item: CleanableItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isSelected.toggle()
    }

    func setAllSelected(_ selected: Bool) {
        for index in items.indices { items[index].isSelected = selected }
    }

    func performRemoval() async {
        phase = .removing
        let selected = selectedItems
        let (removalResults, removalBanner) = await engine.remove(items: selected)
        results = removalResults
        banner = removalBanner
        phase = .done
        if let historyLabel {
            let succeeded = Set(removalResults.filter(\.success).map(\.url))
            let freedItems = selected.filter { succeeded.contains($0.url) }
            await CleaningHistoryStore.shared.record(
                module: historyLabel,
                bytesFreed: freedItems.compactMap(\.sizeBytes).reduce(0, +),
                itemCount: freedItems.count
            )
            let sizeByURL = Dictionary(uniqueKeysWithValues: selected.compactMap { item in
                item.sizeBytes.map { (item.url, $0) }
            })
            await ActionLogStore.shared.append(
                ActionLogStore.records(module: historyLabel, action: "trashed",
                                       results: removalResults, sizes: sizeByURL)
            )
        }
    }
}
