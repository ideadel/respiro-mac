import Foundation

enum ElevationError: LocalizedError {
    case userCancelled
    case blockedBySafetyList(String)
    case scriptFailed(status: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Autenticazione annullata dall'utente."
        case .blockedBySafetyList(let path):
            return "Percorso bloccato dalla lista di sicurezza: \(path)"
        case .scriptFailed(let status, let stderr):
            return "Rimozione con privilegi fallita (codice \(status)): \(stderr)"
        }
    }
}

/// Removes root-owned files via osascript "with administrator privileges"
/// (native macOS password/Touch ID prompt). Items are moved into the real
/// user's Trash and chown-ed back to the user — never rm -rf — so they stay
/// recoverable.
struct PrivilegedRemovalService {
    func removeElevated(paths: [URL]) async throws {
        guard !paths.isEmpty else { return }
        // Defense-in-depth: re-validate every path right before building the command.
        for url in paths {
            guard DenyList.validateForRemoval(url) else {
                throw ElevationError.blockedBySafetyList(url.path)
            }
        }
        // The elevated shell runs as root, where "~" is /var/root — build the
        // real user's Trash path in Swift and pass it as an explicit literal.
        let trashDir = NSHomeDirectory() + "/.Trash"
        let user = NSUserName()
        let stamp = Int(Date().timeIntervalSince1970)
        var parts = ["mkdir -p \(shellQuote(trashDir))"]
        for path in paths {
            let dest = "\(trashDir)/\(path.lastPathComponent)-\(stamp)"
            parts.append("mv -f \(shellQuote(path.path)) \(shellQuote(dest))")
            parts.append("chown -R \(shellQuote(user)) \(shellQuote(dest))")
        }
        let shellCommand = parts.joined(separator: " && ")
        try await ElevatedCommandRunner().run(shellCommand)
    }

    private func shellQuote(_ s: String) -> String {
        ElevatedCommandRunner.shellQuote(s)
    }
}
