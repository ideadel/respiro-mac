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
    @Published var showForceQuitAlert = false
    @Published var appIsRunning = false

    private let finder = LeftoverFinder()
    private let sizeCalculator = SizeCalculator()
    private let removalService = RemovalService()
    private let privilegedService = PrivilegedRemovalService()
    private let terminator = AppTerminator()
    private var auxiliaryIds: Set<String> = []

    var selectedItems: [LeftoverItem] { items.filter(\.isSelected) }
    var selectedSize: Int64 { selectedItems.compactMap(\.sizeBytes).reduce(0, +) }
    var elevatedSelectedCount: Int { selectedItems.filter(\.requiresElevation).count }
    var selectedReceiptCount: Int {
        selectedItems.filter { $0.kind != .file }.count
    }
    /// Whether the result view should point at Impostazioni di Sistema ›
    /// Elementi di login (SMAppService registrations can't be enumerated).
    var hadLoginItemHints: Bool {
        !auxiliaryIds.isEmpty || items.contains { $0.launchdLabel != nil }
    }

    func load(app: InstalledApp, allApps: [InstalledApp] = []) async {
        phase = .loading
        auxiliaryIds = AppBundleInspector.auxiliaryBundleIds(of: app)
        appIsRunning = terminator.isRunning(bundleIds: processIds(for: app))
        var loaded = await finder.findLeftovers(for: app, allApps: allApps)
        let sizes = await sizeCalculator.totalSize(of: loaded)
        loaded = loaded.map { item in
            var item = item
            if item.sizeBytes == nil {
                item.sizeBytes = sizes[item.id]
            }
            return item
        }
        items = loaded
        phase = .reviewing
    }

    func toggleSelection(_ item: LeftoverItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isSelected.toggle()
    }

    func performRemoval(app: InstalledApp, forceQuit: Bool = false) async {
        errorBanner = nil
        // 1. The app (and its helpers) must not be running: processes would
        //    recreate files and survive the bundle's move to the Trash.
        let ids = processIds(for: app)
        if forceQuit {
            await terminator.forceQuit(bundleIds: ids)
        } else if !(await terminator.quit(bundleIds: ids)) {
            showForceQuitAlert = true
            return
        }
        phase = .removing

        let selected = selectedItems
        let files = selected.filter { $0.kind == .file }
        let receipts = selected.filter { $0.kind != .file }
        let normal = files.filter { !$0.requiresElevation }
        let elevated = files.filter(\.requiresElevation)

        // 2. Boot out gui-domain launchd jobs (no elevation needed) so no
        //    process lingers after its plist is trashed.
        for item in selected where item.launchdDomain == .userGui {
            if let label = item.launchdLabel {
                _ = try? await ProcessRunner.run("/bin/launchctl", ["bootout", "gui/\(getuid())/\(label)"])
            }
        }

        var allResults = await removalService.moveToTrash(normal)

        // 3. One elevated script (single password prompt): system bootouts,
        //    file moves, receipt forgetting — with per-item verification.
        let systemLabels = selected.compactMap { $0.launchdDomain == .system ? $0.launchdLabel : nil }
        let packageIds: [String] = receipts.compactMap {
            if case .packageReceipt(let id) = $0.kind { return id } else { return nil }
        }
        if !elevated.isEmpty || !packageIds.isEmpty || !systemLabels.isEmpty {
            do {
                let outcome = try await privilegedService.removeElevated(
                    paths: elevated.map(\.url),
                    bootoutLabels: systemLabels,
                    forgetPackageIds: packageIds
                )
                allResults += elevated.map {
                    let removed = outcome.removedPaths.contains($0.url.path)
                    return RemovalResult(url: $0.url, category: $0.category, success: removed,
                                         errorDescription: removed ? nil : "Il file non è stato rimosso")
                }
                allResults += receipts.map { item in
                    let id: String
                    if case .packageReceipt(let packageId) = item.kind { id = packageId } else { id = "" }
                    let forgotten = outcome.forgottenPackageIds.contains(id)
                    return RemovalResult(url: item.url, category: item.category, success: forgotten,
                                         errorDescription: forgotten ? nil : "Ricevuta non dimenticata")
                }
            } catch let error as ElevationError {
                if case .userCancelled = error {
                    errorBanner = "Rimozione con privilegi annullata — gli elementi di sistema non sono stati toccati."
                } else {
                    errorBanner = error.localizedDescription
                }
                allResults += (elevated + receipts).map {
                    RemovalResult(url: $0.url, category: $0.category, success: false,
                                  errorDescription: error.localizedDescription)
                }
            } catch {
                errorBanner = error.localizedDescription
                allResults += (elevated + receipts).map {
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

        let succeeded = Set(allResults.filter(\.success).map(\.url))
        let freedItems = selected.filter { succeeded.contains($0.url) }
        await CleaningHistoryStore.shared.record(
            module: "trasloco",
            bytesFreed: freedItems.compactMap(\.sizeBytes).reduce(0, +),
            itemCount: freedItems.count + (appRemoved ? 1 : 0)
        )
        let sizeByURL = Dictionary(uniqueKeysWithValues: selected.compactMap { item in
            item.sizeBytes.map { (item.url, $0) }
        })
        let elevatedURLs = Set(elevated.map(\.url))
        let receiptURLs = Set(receipts.map(\.url))
        await ActionLogStore.shared.append(allResults.map { result in
            let action: String
            if receiptURLs.contains(result.url) { action = "pkgForget" }
            else if elevatedURLs.contains(result.url) { action = "deletedElevated" }
            else { action = "trashed" }
            return ActionRecord(date: Date(), module: "trasloco", path: result.url.path,
                                bytes: sizeByURL[result.url] ?? 0, action: action,
                                success: result.success)
        })
    }

    private func processIds(for app: InstalledApp) -> [String] {
        [app.bundleIdentifier].compactMap { $0 } + auxiliaryIds.sorted()
    }
}
