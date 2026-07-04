import AppKit
import Foundation

enum FullDiskAccessChecker {
    /// Heuristic: Safari bookmarks live in a TCC-protected folder.
    static var hasFullDiskAccess: Bool {
        let probe = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari/Bookmarks.plist")
        return FileManager.default.isReadableFile(atPath: probe.path)
    }

    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
