import Foundation

struct SystemExtensionRegistration: Equatable {
    let teamID: String
    let bundleID: String
    let state: String

    var isActive: Bool {
        let lower = state.lowercased()
        return lower.contains("activated") || lower.contains("enabled")
    }
}

/// Discovers and uninstalls macOS System Extensions (camera, network, …)
/// registered via `systemextensionsctl`. Plain Trash moves cannot remove an
/// active extension — the OS keeps the container and plugin alive.
enum SystemExtensionService {
    static func listRegistrations() async -> [SystemExtensionRegistration] {
        guard let result = try? await ProcessRunner.run("/usr/bin/systemextensionsctl", ["list"]),
              result.status == 0 else { return [] }
        return parseListOutput(result.stdout)
    }

    /// Parses `systemextensionsctl list` tab-separated rows (lines starting with `*`).
    static func parseListOutput(_ output: String) -> [SystemExtensionRegistration] {
        var registrations: [SystemExtensionRegistration] = []
        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let text = String(line)
            guard text.hasPrefix("*") else { continue }
            let cols = text.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard cols.count >= 6 else { continue }
            let teamID = cols[2].trimmingCharacters(in: .whitespaces)
            let bundleID = cols[4].trimmingCharacters(in: .whitespaces)
            let state = cols[5].trimmingCharacters(in: .whitespaces)
            guard teamID.count >= 8, bundleID.contains(".") else { continue }
            registrations.append(SystemExtensionRegistration(teamID: teamID, bundleID: bundleID, state: state))
        }
        return registrations
    }

    static func registrations(forBundleIds ids: Set<String>) async -> [SystemExtensionRegistration] {
        guard !ids.isEmpty else { return [] }
        let installed = await listRegistrations()
        return installed.filter { ids.contains($0.bundleID) }
    }

    static func isExtensionInactive(bundleID: String, among registrations: [SystemExtensionRegistration]) -> Bool {
        !registrations.contains { $0.bundleID == bundleID && $0.isActive }
    }

    /// Bundle ids from auxiliary helpers and leftover paths (camera / system extensions).
    static func bundleIds(from items: [LeftoverItem], auxiliaryIds: Set<String>) -> Set<String> {
        var ids = auxiliaryIds
        for item in items {
            if let id = bundleId(fromExtensionArtifact: item.url) { ids.insert(id) }
        }
        return ids
    }

    static func bundleId(fromExtensionArtifact url: URL) -> String? {
        let name = url.lastPathComponent
        guard name.contains(".") else { return nil }
        if name.contains("camera-extension") || name.contains("systemextension") {
            return name
        }
        return nil
    }

    static func isExtensionArtifact(_ url: URL) -> Bool {
        bundleId(fromExtensionArtifact: url) != nil
    }
}
