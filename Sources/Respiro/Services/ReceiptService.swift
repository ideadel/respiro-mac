import Foundation

/// Installer package receipts (`pkgutil --pkgs`). A receipt makes macOS
/// believe the app is still installed; it is removed with `pkgutil --forget`,
/// never by trashing files under /var/db/receipts.
struct ReceiptService {
    func receiptItems(for app: InstalledApp, auxIds: Set<String>, vendorToken: String?) async -> [LeftoverItem] {
        guard let (status, stdout, _) = try? await ProcessRunner.run("/usr/sbin/pkgutil", ["--pkgs"]),
              status == 0 else { return [] }
        var items: [LeftoverItem] = []
        for line in stdout.split(separator: "\n") {
            let packageId = line.trimmingCharacters(in: .whitespaces)
            guard !packageId.isEmpty,
                  let reason = Self.matchReason(packageId: packageId, app: app,
                                                auxIds: auxIds, vendorToken: vendorToken)
            else { continue }
            items.append(LeftoverItem(
                url: URL(fileURLWithPath: "/var/db/receipts/\(packageId).plist"),
                category: .pkgReceipts,
                sizeBytes: 0,
                isSelected: reason != .vendorMatch,
                requiresElevation: true,
                matchReason: reason,
                kind: .packageReceipt(packageId)
            ))
        }
        return items
    }

    static func matchReason(packageId: String, app: InstalledApp,
                            auxIds: Set<String> = [], vendorToken: String? = nil) -> MatchReason? {
        let p = packageId.lowercased()
        guard !p.hasPrefix("com.apple.") else { return nil }
        if let bundleId = app.bundleIdentifier?.lowercased(), !bundleId.isEmpty {
            if p == bundleId { return .bundleIdExact }
            if p.hasPrefix(bundleId) || p.contains(bundleId) { return .bundleIdPrefix }
        }
        if auxIds.contains(where: { p == $0 || p.contains($0) }) { return .helperBundleId }
        // Vendor receipts ("us.zoom.pkg.videomeeting" for bundle "us.zoom.xos")
        // need a recognizable piece of the app name too, otherwise far too broad.
        if let vendor = vendorToken, p.contains(".\(vendor).") || p.hasPrefix("\(vendor).") || p.hasSuffix(".\(vendor)") {
            let nameTokens = app.displayName.lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { $0.count >= 4 }
            if nameTokens.contains(where: { p.contains($0) }) {
                return .vendorMatch
            }
        }
        return nil
    }
}
