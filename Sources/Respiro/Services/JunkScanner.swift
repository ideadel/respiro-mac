import Foundation

/// System Junk: enumerates well-known junk locations one level deep.
/// Everything found is safely regenerable (caches, logs, saved state,
/// developer junk) and is only ever moved to the Trash.
final class JunkScanner {
    func scan() async -> [CleanableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [CleanableItem] = []

        func addChildren(of directory: URL, group: String, systemLevel: Bool = false) {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { return }
            for child in children where !DenyList.isBlockedPath(child) {
                let elevated = systemLevel && !FileManager.default.isDeletableFile(atPath: child.path)
                items.append(CleanableItem(url: child, group: group, requiresElevation: elevated))
            }
        }

        addChildren(of: home.appendingPathComponent("Library/Caches"), group: "Cache utente")
        addChildren(of: home.appendingPathComponent("Library/Logs"), group: "Log utente")
        addChildren(of: home.appendingPathComponent("Library/Saved Application State"),
                    group: "Stato applicazioni salvato")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/Archives"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"),
                    group: "Allegati Mail")
        addChildren(of: URL(fileURLWithPath: "/Library/Caches"),
                    group: "Cache di sistema", systemLevel: true)

        return items
    }
}
