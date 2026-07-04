import Foundation
@preconcurrency import UserNotifications
import ServiceManagement

/// Periodic background junk scan with a local notification when recoverable
/// space passes the threshold. Runs off a plain Timer while the app (or its
/// menu-bar presence) is alive — no daemon, no launchd job of our own.
@MainActor
final class BackgroundScanScheduler: ObservableObject {
    enum Keys {
        static let enabled = "autoScanEnabled"
        static let intervalHours = "autoScanIntervalHours"
        static let thresholdMB = "autoScanThresholdMB"
        static let lastScan = "autoScanLastDate"
    }

    static let shared = BackgroundScanScheduler()

    @Published var lastResultDescription: String?

    private var timer: Timer?
    private let defaults = UserDefaults.standard

    /// UNUserNotificationCenter aborts in processes without an app bundle
    /// (plain `swift build` executable, self-test runs).
    private var hasBundle: Bool { Bundle.main.bundleIdentifier != nil }

    private init() {
        defaults.register(defaults: [Keys.intervalHours: 24, Keys.thresholdMB: 1024])
    }

    func start() {
        timer?.invalidate()
        // Cheap hourly tick; the real cadence is enforced by lastScan.
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in await BackgroundScanScheduler.shared.tick() }
        }
        Task { await tick() }
    }

    func tick() async {
        guard defaults.bool(forKey: Keys.enabled) else { return }
        let interval = TimeInterval(max(1, defaults.integer(forKey: Keys.intervalHours))) * 3600
        let last = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastScan))
        guard Date().timeIntervalSince(last) >= interval else { return }
        await runScan()
    }

    func runScan() async {
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastScan)
        let junk = await JunkScanner().scan()
        let sizes = await SizeCalculator().sizes(for: junk.map(\.url))
        let junkBytes = sizes.values.reduce(0, +)
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash", isDirectory: true)
        let trashBytes = await Task.detached { SizeCalculator.recursiveSize(of: trashURL) }.value
        let total = junkBytes + trashBytes
        lastResultDescription = "Ultima scansione: \(formatBytes(total)) recuperabili"
        await CleaningHistoryStore.shared.snapshotFreeSpaceIfNeeded()

        let thresholdBytes = Int64(max(1, defaults.integer(forKey: Keys.thresholdMB))) * 1_000_000
        if total >= thresholdBytes {
            notify(recoverable: total)
        }
    }

    private func notify(recoverable: Int64) {
        guard hasBundle else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Respiro"
            content.body = "Puoi liberare circa \(formatBytes(recoverable)) tra file inutili e Cestino. Apri Respiro per fare pulizia."
            let request = UNNotificationRequest(identifier: "respiro.autoscan",
                                                content: content, trigger: nil)
            center.add(request)
        }
    }

    // MARK: - Launch at login (SMAppService, macOS 13+)

    var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        guard hasBundle else { return }
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
