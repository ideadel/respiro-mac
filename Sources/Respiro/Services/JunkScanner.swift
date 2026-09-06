import Foundation

/// Aria: elenca cartelle rigenerabili un livello in profondità.
/// Tutto finisce nel Cestino. I gruppi incerti partono deselezionati.
final class JunkScanner {
    /// Cache che non sono "spazio da liberare": sync, foto, identità.
    static let skippedCacheNames: Set<String> = [
        "com.apple.bird",
        "com.apple.clouddocs",
        "cloudkit",
        "com.apple.photos",
        "com.apple.photos.imagedetection",
        "com.apple.photolibraryd",
        "com.apple.akd",
        "com.apple.assistant",
        "com.apple.passd",
        "com.apple.siri",
        "com.apple.homed",
        "com.apple.addressbook",
        "com.apple.icloud",
        "familycircle",
        "com.apple.accountsd",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.lastpass.LastPass",
        "com.bitwarden.desktop",
        "org.whispersystems.signal-desktop",
    ]

    static func shouldSkipCacheName(_ name: String) -> Bool {
        let lowered = name.lowercased()
        if lowered.hasPrefix("com.apple.") { return true }
        if lowered.hasPrefix("familycircle") { return true }
        if lowered.contains("respirofixture") { return true }
        if skippedCacheNames.contains(lowered) { return true }
        if lowered.contains("photos") && lowered.contains("apple") { return true }
        if lowered.contains("icloud") || lowered.contains("clouddocs") { return true }
        if lowered.contains("keychain") || lowered.contains("1password") { return true }
        return false
    }

    /// Solo ciò che esiste e che Aria può davvero spostare nel Cestino.
    static func isOfferable(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        if shouldSkipCacheName(url.lastPathComponent) { return false }
        if DenyList.isBlockedPath(url) || !DenyList.validateForRemoval(url) { return false }
        return true
    }

    static func requiresElevation(for url: URL, systemLevel: Bool) -> Bool {
        if systemLevel { return true }
        if !FileManager.default.isDeletableFile(atPath: url.path) { return true }
        if !FileManager.default.isWritableFile(atPath: url.path) { return true }
        return false
    }

    static func defaultSelected(forGroup group: String) -> Bool {
        switch group {
        case "Stato applicazioni salvato", "Allegati Mail",
             "Archivi Xcode", "Simulatori iOS", "Residui orfani":
            return false
        default:
            return true
        }
    }

    func scan() async -> [CleanableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [CleanableItem] = []

        func addChildren(of directory: URL, group: String, systemLevel: Bool = false,
                         skipCacheNames: Bool = false) {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { return }
            let selected = Self.defaultSelected(forGroup: group)
            for child in children {
                if skipCacheNames && Self.shouldSkipCacheName(child.lastPathComponent) { continue }
                if !Self.isOfferable(child) { continue }
                let elevated = Self.requiresElevation(for: child, systemLevel: systemLevel)
                items.append(CleanableItem(url: child, group: group,
                                           isSelected: selected, requiresElevation: elevated))
            }
        }

        addChildren(of: home.appendingPathComponent("Library/Caches"),
                    group: "Cache utente", skipCacheNames: true)
        addChildren(of: home.appendingPathComponent("Library/Logs"), group: "Log utente")
        addChildren(of: home.appendingPathComponent("Library/Logs/DiagnosticReports"),
                    group: "Report di crash")
        addChildren(of: home.appendingPathComponent("Library/Saved Application State"),
                    group: "Stato applicazioni salvato")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/Archives"),
                    group: "Archivi Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/watchOS DeviceSupport"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/DocumentationCache"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/Xcode/UserData/IB Support"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"),
                    group: "Junk di Xcode")
        addChildren(of: home.appendingPathComponent("Library/Developer/CoreSimulator/Devices"),
                    group: "Simulatori iOS")
        addChildren(of: home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"),
                    group: "Allegati Mail")

        items += await OrphanResidueScanner().scan()
        return items
    }
}

/// Cartelle nominate con un bundle id di un'app che non è più installata.
/// Solo match esatti / prefissi identitari — mai per nome.
struct OrphanResidueScanner {
    private static let roots: [(sub: String, group: String, selected: Bool)] = [
        ("Preferences", "Residui orfani", false),
        ("HTTPStorages", "Residui orfani", false),
        ("WebKit", "Residui orfani", false),
        ("Cookies", "Residui orfani", false),
        ("Containers", "Residui orfani", false),
    ]

    func scan() async -> [CleanableItem] {
        let installed = await AppScanner().scanInstalledApps()
        let ids = Set(installed.compactMap { $0.bundleIdentifier?.lowercased() })
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [CleanableItem] = []

        for root in Self.roots {
            let dir = home.appendingPathComponent("Library/\(root.sub)", isDirectory: true)
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }
            for child in children {
                if !JunkScanner.isOfferable(child) { continue }
                let name = orphanBundleStem(child.lastPathComponent)
                guard looksLikeBundleId(name), !DenyList.isBlockedBundleId(name) else { continue }
                if ids.contains(where: { LeftoverFinder.matchesBundleIdentity(name, bundleId: $0) }) {
                    continue
                }
                items.append(CleanableItem(
                    url: child,
                    group: root.group,
                    detail: "Nessuna app installata con questo bundle id",
                    isSelected: root.selected
                ))
            }
        }
        return items
    }

    private func looksLikeBundleId(_ name: String) -> Bool {
        let parts = name.split(separator: ".")
        return parts.count >= 3 && name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
    }

    private func orphanBundleStem(_ filename: String) -> String {
        var name = filename
        for suffix in [".plist", ".savedState", ".binarycookies", ".log"] {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        return name.lowercased()
    }
}
