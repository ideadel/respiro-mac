import Foundation

struct InstalledApp: Identifiable, Hashable {
    let bundleIdentifier: String?
    let displayName: String
    let bundleURL: URL
    let version: String?

    var id: String { bundleIdentifier ?? bundleURL.path }
}
