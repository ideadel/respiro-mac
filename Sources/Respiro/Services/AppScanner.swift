import Foundation

final class AppScanner {
    func scanInstalledApps() async -> [InstalledApp] {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        ]
        var apps: [InstalledApp] = []
        for root in roots {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }
            for url in contents where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url) else { continue }
                let bundleId = bundle.bundleIdentifier
                if DenyList.isBlockedBundleId(bundleId) || DenyList.isBlockedPath(url) { continue }
                if bundleId != nil, bundleId == Bundle.main.bundleIdentifier { continue }
                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                apps.append(InstalledApp(bundleIdentifier: bundleId, displayName: name,
                                         bundleURL: url, version: version))
            }
        }
        return apps.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}
