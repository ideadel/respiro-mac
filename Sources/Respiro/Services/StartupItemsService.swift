import Foundation

enum StartupDomain: String, CaseIterable {
    case userAgent = "Agenti utente"
    case systemAgent = "Agenti di sistema"
    case systemDaemon = "Daemon di sistema"
}

struct StartupItem: Identifiable {
    let id = UUID()
    let label: String
    let plistURL: URL
    let program: String?
    let domain: StartupDomain
    var isDisabled: Bool
    var requiresElevationToToggle: Bool { domain != .userAgent }
}

/// Lists and toggles LaunchAgents/LaunchDaemons. Apple items are never shown.
final class StartupItemsService {
    func list() async -> [StartupItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let uid = getuid()
        let userDisabled = await disabledLabels(domain: "gui/\(uid)")
        let systemDisabled = await disabledLabels(domain: "system")
        let dirs: [(URL, StartupDomain, Set<String>)] = [
            (home.appendingPathComponent("Library/LaunchAgents"), .userAgent, userDisabled),
            (URL(fileURLWithPath: "/Library/LaunchAgents"), .systemAgent, systemDisabled),
            (URL(fileURLWithPath: "/Library/LaunchDaemons"), .systemDaemon, systemDisabled),
        ]
        var items: [StartupItem] = []
        for (dir, domain, disabled) in dirs {
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
                items.append(StartupItem(label: label, plistURL: url, program: program,
                                         domain: domain, isDisabled: disabled.contains(label)))
            }
        }
        return items.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    /// Parses `launchctl print-disabled <domain>` output ("label" => disabled/true).
    private func disabledLabels(domain: String) async -> Set<String> {
        guard let (status, stdout, _) = try? await ProcessRunner.run("/bin/launchctl", ["print-disabled", domain]),
              status == 0 else { return [] }
        var labels = Set<String>()
        for line in stdout.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("=>"),
                  trimmed.hasSuffix("true") || trimmed.hasSuffix("disabled"),
                  let start = trimmed.firstIndex(of: "\""),
                  let end = trimmed.lastIndex(of: "\""), start < end
            else { continue }
            labels.insert(String(trimmed[trimmed.index(after: start)..<end]))
        }
        return labels
    }

    func setDisabled(_ item: StartupItem, _ disabled: Bool) async throws {
        let verb = disabled ? "disable" : "enable"
        switch item.domain {
        case .userAgent:
            let gui = "gui/\(getuid())"
            let (status, _, stderr) = try await ProcessRunner.run("/bin/launchctl", [verb, "\(gui)/\(item.label)"])
            guard status == 0 else {
                throw RemovalError(message: "launchctl \(verb) fallito (codice \(status)): \(stderr)")
            }
            // Best effort: apply immediately without waiting for next login.
            if disabled {
                _ = try? await ProcessRunner.run("/bin/launchctl", ["bootout", "\(gui)/\(item.label)"])
            } else {
                _ = try? await ProcessRunner.run("/bin/launchctl", ["bootstrap", gui, item.plistURL.path])
            }
        case .systemAgent, .systemDaemon:
            let quote = ElevatedCommandRunner.shellQuote
            var command = "launchctl \(verb) \(quote("system/\(item.label)"))"
            if disabled {
                command += "; launchctl bootout \(quote("system/\(item.label)")) || true"
            } else {
                command += "; launchctl bootstrap system \(quote(item.plistURL.path)) || true"
            }
            try await ElevatedCommandRunner().run(command)
        }
    }
}
