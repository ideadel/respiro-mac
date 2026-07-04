import AppKit

/// Quits the target app (and its helper processes) before uninstalling, so
/// files are not recreated and the trashed bundle leaves no running copy.
struct AppTerminator {
    func isRunning(bundleIds: [String]) -> Bool {
        !running(bundleIds: bundleIds).isEmpty
    }

    /// Polite quit with a grace period. Returns false if something is still
    /// running afterwards (caller decides whether to force-quit).
    func quit(bundleIds: [String], gracePeriod: TimeInterval = 5) async -> Bool {
        let apps = running(bundleIds: bundleIds)
        guard !apps.isEmpty else { return true }
        for app in apps { app.terminate() }
        let deadline = Date().addingTimeInterval(gracePeriod)
        while Date() < deadline {
            if running(bundleIds: bundleIds).isEmpty { return true }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return running(bundleIds: bundleIds).isEmpty
    }

    func forceQuit(bundleIds: [String]) async {
        for app in running(bundleIds: bundleIds) { app.forceTerminate() }
        // Give launchd a moment to reap before files get moved.
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private func running(bundleIds: [String]) -> [NSRunningApplication] {
        bundleIds.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }
}
