import Foundation

final class LeftoverFinder {
    func findLeftovers(for app: InstalledApp) async -> [LeftoverItem] {
        guard !DenyList.isBlockedBundleId(app.bundleIdentifier) else { return [] }
        var items: [LeftoverItem] = []
        for root in SearchRoots.all {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root.url, includingPropertiesForKeys: nil, options: []
            ) else { continue }
            for candidate in contents {
                if DenyList.isBlockedPath(candidate) { continue }
                let reason: MatchReason?
                if root.matchesPlistLabel {
                    reason = plistLabelMatches(candidate, app: app) ? .plistLabelMatch : nil
                } else {
                    reason = Self.matchReason(candidateName: candidate.lastPathComponent,
                                              app: app, allowNameMatch: root.allowsNameMatch)
                }
                guard let matchReason = reason else { continue }
                let requiresElevation = root.isSystemLevel
                    && !FileManager.default.isDeletableFile(atPath: candidate.path)
                items.append(LeftoverItem(url: candidate, category: root.category,
                                          sizeBytes: nil, requiresElevation: requiresElevation,
                                          matchReason: matchReason))
            }
        }
        return items.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    static func matchReason(candidateName: String, app: InstalledApp, allowNameMatch: Bool) -> MatchReason? {
        let c = candidateName.lowercased()
        if let bundleId = app.bundleIdentifier?.lowercased(), !bundleId.isEmpty {
            if c == bundleId { return .bundleIdExact }
            // Covers suffixed variants ("com.foo.App.plist", ".savedState") and
            // group-container names ("TEAMID.com.foo.App").
            if c.hasPrefix(bundleId) || c.contains(bundleId) { return .bundleIdPrefix }
        }
        guard allowNameMatch else { return nil }
        let d = app.displayName.lowercased().replacingOccurrences(of: " ", with: "")
        // Short names ("Note", "Mail") would match far too much.
        if d.count >= 4, c.replacingOccurrences(of: " ", with: "").contains(d) {
            return .nameMatch
        }
        return nil
    }

    /// LaunchAgents/LaunchDaemons match only via the plist "Label" key, never filename.
    private func plistLabelMatches(_ url: URL, app: InstalledApp) -> Bool {
        guard url.pathExtension == "plist",
              let bundleId = app.bundleIdentifier?.lowercased(), !bundleId.isEmpty,
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let label = (plist["Label"] as? String)?.lowercased()
        else { return false }
        return label == bundleId || label.hasPrefix(bundleId + ".")
    }
}
