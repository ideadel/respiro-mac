import Foundation

/// Safety-critical hard exclusions. Checked at scan time AND re-checked
/// immediately before every removal command (defense in depth).
enum DenyList {
    static let blockedPathPrefixes = ["/System", "/Library/Apple"]
    static let blockedBundleIdPrefixes = ["com.apple."]

    static func isBlockedBundleId(_ bundleId: String?) -> Bool {
        guard let id = bundleId?.lowercased() else { return false }
        return blockedBundleIdPrefixes.contains { id.hasPrefix($0) }
    }

    /// Checked against the symlink-resolved path to prevent symlink-escape bypass.
    static func isBlockedPath(_ url: URL) -> Bool {
        let resolved = url.resolvingSymlinksInPath().path
        return blockedPathPrefixes.contains { resolved.hasPrefix($0) }
    }

    /// User content folders the large-files and duplicate scanners operate on.
    static let userContentRoots: [URL] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return ["Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures", "Public"]
            .map { home.appendingPathComponent($0, isDirectory: true) }
    }()

    /// A URL may be removed only if it is a strict descendant of one of the
    /// declared search roots, an Applications folder, a junk-cleanup root or a
    /// user content folder — never a bare root itself, never anything deny-listed.
    static func validateForRemoval(_ url: URL) -> Bool {
        if isBlockedPath(url) { return false }
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let home = FileManager.default.homeDirectoryForCurrentUser
        let allowedParents = SearchRoots.all.map(\.url) + userContentRoots + [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            home.appendingPathComponent("Applications", isDirectory: true),
            home.appendingPathComponent("Library/Developer", isDirectory: true),
            URL(fileURLWithPath: "/Library/Caches", isDirectory: true),
        ]
        let components = resolved.pathComponents
        for parent in allowedParents {
            let parentComponents = parent.standardizedFileURL.pathComponents
            if components.count > parentComponents.count,
               Array(components.prefix(parentComponents.count)) == parentComponents {
                return true
            }
        }
        return false
    }
}
