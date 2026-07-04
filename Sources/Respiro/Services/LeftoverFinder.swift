import Foundation

final class LeftoverFinder {
    /// `allApps` lets the vendor heuristic skip folders shared with another
    /// installed app from the same vendor (e.g. "Google" while Drive is
    /// still installed alongside Chrome).
    func findLeftovers(for app: InstalledApp, allApps: [InstalledApp] = []) async -> [LeftoverItem] {
        guard !DenyList.isBlockedBundleId(app.bundleIdentifier) else { return [] }

        let auxIds = AppBundleInspector.auxiliaryBundleIds(of: app)
        let vendorToken = Self.effectiveVendorToken(for: app, allApps: allApps)

        var items: [LeftoverItem] = []
        for root in SearchRoots.all {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root.url, includingPropertiesForKeys: nil, options: []
            ) else { continue }
            for candidate in contents {
                if DenyList.isBlockedPath(candidate) { continue }
                var launchdLabel: String?
                let reason: MatchReason?
                if root.matchesPlistLabel {
                    launchdLabel = matchedPlistLabel(candidate, app: app, auxIds: auxIds)
                    reason = launchdLabel != nil ? .plistLabelMatch : nil
                } else {
                    reason = Self.matchReason(candidateName: candidate.lastPathComponent,
                                              app: app, auxIds: auxIds,
                                              allowNameMatch: root.allowsNameMatch,
                                              vendorToken: root.allowsVendorMatch ? vendorToken : nil)
                    // Helper binaries are launchd jobs too (label == filename).
                    if root.category == .privilegedHelpers, reason != nil {
                        launchdLabel = candidate.lastPathComponent
                    }
                }
                guard let matchReason = reason else { continue }
                let requiresElevation = root.isSystemLevel
                    && !FileManager.default.isDeletableFile(atPath: candidate.path)
                items.append(LeftoverItem(url: candidate, category: root.category,
                                          sizeBytes: nil,
                                          isSelected: matchReason != .vendorMatch,
                                          requiresElevation: requiresElevation,
                                          matchReason: matchReason,
                                          launchdLabel: launchdLabel,
                                          launchdDomain: launchdLabel.map { _ in
                                              Self.launchdDomain(for: root.category)
                                          }))
            }
        }

        items += await ReceiptService().receiptItems(for: app, auxIds: auxIds, vendorToken: vendorToken)
        return items.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    static func matchReason(candidateName: String, app: InstalledApp, auxIds: Set<String> = [],
                            allowNameMatch: Bool, vendorToken: String? = nil) -> MatchReason? {
        let c = candidateName.lowercased()
        if let bundleId = app.bundleIdentifier?.lowercased(), !bundleId.isEmpty {
            if c == bundleId { return .bundleIdExact }
            // Covers suffixed variants ("com.foo.App.plist", ".savedState") and
            // group-container names ("TEAMID.com.foo.App").
            if c.hasPrefix(bundleId) || c.contains(bundleId) { return .bundleIdPrefix }
        }
        for auxId in auxIds where c == auxId || c.hasPrefix(auxId + ".") || c.contains(auxId) {
            return .helperBundleId
        }
        if allowNameMatch {
            let d = app.displayName.lowercased().replacingOccurrences(of: " ", with: "")
            // Short names ("Note", "Mail") would match far too much.
            if d.count >= 4, c.replacingOccurrences(of: " ", with: "").contains(d) {
                return .nameMatch
            }
        }
        // Vendor folders only on exact equality: "Google" yes, "GoogleUpdater" no.
        if let vendor = vendorToken, c == vendor { return .vendorMatch }
        return nil
    }

    /// Second bundle-id component ("com.VENDOR.app"), filtered against
    /// generic tokens that would match unrelated folders.
    static func vendorToken(from bundleId: String) -> String? {
        let parts = bundleId.lowercased().split(separator: ".")
        guard parts.count >= 3 else { return nil }
        let token = String(parts[1])
        let stoplist: Set<String> = ["com", "org", "net", "io", "co", "app", "apps",
                                     "sh", "github", "gitlab", "software", "macos", "mac", "www"]
        guard token.count >= 4, !stoplist.contains(token) else { return nil }
        return token
    }

    private static func effectiveVendorToken(for app: InstalledApp, allApps: [InstalledApp]) -> String? {
        guard let bundleId = app.bundleIdentifier,
              let token = vendorToken(from: bundleId) else { return nil }
        // Another installed app from the same vendor still needs that folder.
        let shared = allApps.contains { other in
            other.id != app.id && other.bundleIdentifier.flatMap(vendorToken(from:)) == token
        }
        return shared ? nil : token
    }

    private static func launchdDomain(for category: LeftoverCategory) -> LaunchdDomain {
        switch category {
        // /Library/LaunchAgents load into each user's gui session, not system.
        case .launchAgentsUser, .launchAgentsSystem: return .userGui
        default: return .system
        }
    }

    /// LaunchAgents/LaunchDaemons match only via the plist "Label" key, never
    /// filename. Returns the label so the job can be booted out before removal.
    private func matchedPlistLabel(_ url: URL, app: InstalledApp, auxIds: Set<String>) -> String? {
        guard url.pathExtension == "plist",
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let label = (plist["Label"] as? String)
        else { return nil }
        let lowered = label.lowercased()
        if let bundleId = app.bundleIdentifier?.lowercased(), !bundleId.isEmpty,
           lowered == bundleId || lowered.hasPrefix(bundleId + ".") {
            return label
        }
        if auxIds.contains(where: { lowered == $0 || lowered.hasPrefix($0 + ".") }) {
            return label
        }
        return nil
    }
}
