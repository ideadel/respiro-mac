import Foundation

/// Extracts auxiliary bundle identifiers from a still-installed app bundle:
/// login items, privileged helpers, XPC services and app extensions. These
/// leave their own leftovers (launchd jobs, containers, helper binaries)
/// that never contain the main app's bundle id.
enum AppBundleInspector {
    static func auxiliaryBundleIds(of app: InstalledApp) -> Set<String> {
        let fm = FileManager.default
        let contents = app.bundleURL.appendingPathComponent("Contents", isDirectory: true)
        var ids = Set<String>()

        func addBundleIds(inDirectory dir: URL) {
            guard let children = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
            for child in children {
                if let id = Bundle(url: child)?.bundleIdentifier { ids.insert(id) }
            }
        }
        addBundleIds(inDirectory: contents.appendingPathComponent("Library/LoginItems", isDirectory: true))
        addBundleIds(inDirectory: contents.appendingPathComponent("XPCServices", isDirectory: true))
        addBundleIds(inDirectory: contents.appendingPathComponent("PlugIns", isDirectory: true))
        addBundleIds(inDirectory: contents.appendingPathComponent("Library/SystemExtensions", isDirectory: true))

        // Privileged helper convention (SMJobBless): the filename IS the label.
        let launchServices = contents.appendingPathComponent("Library/LaunchServices", isDirectory: true)
        if let helpers = try? fm.contentsOfDirectory(at: launchServices, includingPropertiesForKeys: nil) {
            ids.formUnion(helpers.map(\.lastPathComponent))
        }
        if let info = Bundle(url: app.bundleURL)?.infoDictionary,
           let privileged = info["SMPrivilegedExecutables"] as? [String: Any] {
            ids.formUnion(privileged.keys)
        }

        if let own = app.bundleIdentifier { ids.remove(own) }
        let lowered = Set(ids.map { $0.lowercased() })
        return lowered.filter { !DenyList.isBlockedBundleId($0) }
    }
}
