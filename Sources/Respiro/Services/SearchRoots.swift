import Foundation

struct SearchRoot {
    let url: URL
    let category: LeftoverCategory
    let isSystemLevel: Bool
    /// Match by parsing the plist "Label" key instead of the filename.
    let matchesPlistLabel: Bool
    /// Whether the low-confidence display-name heuristic applies to this root.
    let allowsNameMatch: Bool
}

enum SearchRoots {
    /// The only 15 locations ever enumerated (one level deep). No recursive
    /// filesystem walk, no Spotlight. iCloud (~/Library/Mobile Documents)
    /// deliberately excluded.
    static let all: [SearchRoot] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        func user(_ sub: String, _ cat: LeftoverCategory, label: Bool = false, name: Bool = false) -> SearchRoot {
            SearchRoot(url: home.appendingPathComponent("Library/\(sub)", isDirectory: true),
                       category: cat, isSystemLevel: false, matchesPlistLabel: label, allowsNameMatch: name)
        }
        func system(_ sub: String, _ cat: LeftoverCategory, label: Bool = false, name: Bool = false) -> SearchRoot {
            SearchRoot(url: URL(fileURLWithPath: "/Library/\(sub)", isDirectory: true),
                       category: cat, isSystemLevel: true, matchesPlistLabel: label, allowsNameMatch: name)
        }
        return [
            user("Preferences", .preferences),
            user("Caches", .caches),
            user("Application Support", .appSupport, name: true),
            user("Logs", .logs, name: true),
            user("Saved Application State", .savedState),
            user("Containers", .containers),
            user("Group Containers", .groupContainers),
            user("LaunchAgents", .launchAgentsUser, label: true),
            user("HTTPStorages", .httpStorages),
            user("WebKit", .webkit),
            user("Cookies", .cookies),
            system("LaunchAgents", .launchAgentsSystem, label: true),
            system("LaunchDaemons", .launchDaemons, label: true),
            system("Application Support", .systemAppSupport, name: true),
            system("Preferences", .systemPreferences),
        ]
    }()
}
