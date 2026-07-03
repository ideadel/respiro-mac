import Foundation

/// Heuristic protection check: flags launch items with executables in
/// suspicious locations and hidden plists. Report-only (items start
/// unselected) — this is NOT an antivirus.
final class ProtectionScanner {
    static let highRiskGroup = "Rischio alto"
    static let reviewGroup = "Da controllare"

    func scan() async -> [CleanableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dirs: [(URL, Bool)] = [
            (home.appendingPathComponent("Library/LaunchAgents"), false),
            (URL(fileURLWithPath: "/Library/LaunchAgents"), true),
            (URL(fileURLWithPath: "/Library/LaunchDaemons"), true),
        ]
        var items: [CleanableItem] = []
        for (dir, systemLevel) in dirs {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: []
            ) else { continue }
            for url in children where url.pathExtension == "plist" {
                guard let data = try? Data(contentsOf: url),
                      let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                      let label = plist["Label"] as? String
                else { continue }
                if label.lowercased().hasPrefix("com.apple.") { continue }
                let program = (plist["Program"] as? String)
                    ?? (plist["ProgramArguments"] as? [String])?.first
                let elevated = systemLevel && !FileManager.default.isDeletableFile(atPath: url.path)

                var group: String?
                var reason: String?
                if url.lastPathComponent.hasPrefix(".") {
                    group = Self.highRiskGroup
                    reason = "File plist nascosto"
                } else if let suspicion = Self.suspicionReason(forProgram: program) {
                    group = Self.highRiskGroup
                    reason = suspicion
                } else if let program, program.hasPrefix(home.appendingPathComponent("Library").path),
                          (plist["RunAtLoad"] as? Bool) == true {
                    group = Self.reviewGroup
                    reason = "Si avvia al login con eseguibile in ~/Library"
                }
                guard let group, let reason else { continue }
                items.append(CleanableItem(url: url, group: group,
                                           detail: "\(label) — \(reason)",
                                           isSelected: false,
                                           requiresElevation: elevated))
            }
        }
        // High-risk findings first.
        return items.sorted { $0.group == Self.highRiskGroup && $1.group != Self.highRiskGroup }
    }

    static func suspicionReason(forProgram program: String?) -> String? {
        guard let program, !program.isEmpty else { return nil }
        for prefix in ["/tmp/", "/private/tmp/", "/var/tmp/", "/private/var/tmp/", "/Users/Shared/"] {
            if program.hasPrefix(prefix) {
                return "Eseguibile in posizione sospetta (\(program))"
            }
        }
        let components = URL(fileURLWithPath: program).pathComponents.dropFirst()
        if components.contains(where: { $0.hasPrefix(".") }) {
            return "Eseguibile in cartella nascosta (\(program))"
        }
        return nil
    }
}
