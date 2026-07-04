import Foundation

struct SearchRoot {
    let url: URL
    let category: LeftoverCategory
    let isSystemLevel: Bool
    /// Match by parsing the plist "Label" key instead of the filename.
    let matchesPlistLabel: Bool
    /// Whether the low-confidence display-name heuristic applies to this root.
    let allowsNameMatch: Bool
    /// Whether folders named exactly after the vendor (second bundle-id
    /// component, e.g. "Google") may match — low confidence, off by default.
    let allowsVendorMatch: Bool
}

enum SearchRoots {
    /// The only locations ever enumerated (one level deep). No recursive
    /// filesystem walk, no Spotlight. iCloud (~/Library/Mobile Documents)
    /// deliberately excluded; /usr/local excluded (nothing there is
    /// bundle-id named, collisions would be rampant). Package receipts are
    /// handled separately via pkgutil, never as files under /var/db.
    static let all: [SearchRoot] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        func user(_ sub: String, _ cat: LeftoverCategory, label: Bool = false,
                  name: Bool = false, vendor: Bool = false) -> SearchRoot {
            SearchRoot(url: home.appendingPathComponent("Library/\(sub)", isDirectory: true),
                       category: cat, isSystemLevel: false, matchesPlistLabel: label,
                       allowsNameMatch: name, allowsVendorMatch: vendor)
        }
        func system(_ sub: String, _ cat: LeftoverCategory, label: Bool = false,
                    name: Bool = false, vendor: Bool = false) -> SearchRoot {
            SearchRoot(url: URL(fileURLWithPath: "/Library/\(sub)", isDirectory: true),
                       category: cat, isSystemLevel: true, matchesPlistLabel: label,
                       allowsNameMatch: name, allowsVendorMatch: vendor)
        }
        // Audio plug-in folders only ever contain type subfolders, so the
        // interesting level is one below the root.
        let audioSubfolders = ["Components", "VST", "VST3", "HAL"]
        return [
            user("Preferences", .preferences),
            user("Preferences/ByHost", .preferences),
            user("Caches", .caches, vendor: true),
            user("Application Support", .appSupport, name: true, vendor: true),
            user("Logs", .logs, name: true, vendor: true),
            user("Logs/DiagnosticReports", .crashReports, name: true),
            user("Saved Application State", .savedState),
            user("Containers", .containers),
            user("Group Containers", .groupContainers),
            user("LaunchAgents", .launchAgentsUser, label: true),
            user("HTTPStorages", .httpStorages),
            user("WebKit", .webkit),
            user("Cookies", .cookies),
            user("Application Scripts", .applicationScripts),
            user("Services", .services, name: true),
            user("Internet Plug-Ins", .internetPlugins, name: true),
            user("QuickLook", .quickLook, name: true),
            user("PreferencePanes", .prefPanes, name: true),
        ]
        + audioSubfolders.map { user("Audio/Plug-Ins/\($0)", .audioPlugins, name: true) }
        + [
            system("LaunchAgents", .launchAgentsSystem, label: true),
            system("LaunchDaemons", .launchDaemons, label: true),
            system("Application Support", .systemAppSupport, name: true, vendor: true),
            system("Preferences", .systemPreferences),
            system("PrivilegedHelperTools", .privilegedHelpers),
            system("Caches", .systemCaches, name: true, vendor: true),
            system("Logs", .systemLogs, name: true),
            system("Internet Plug-Ins", .internetPlugins, name: true),
            system("PreferencePanes", .prefPanes, name: true),
        ]
        + audioSubfolders.map { system("Audio/Plug-Ins/\($0)", .audioPlugins, name: true) }
    }()
}
