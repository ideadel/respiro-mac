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

/// Per-item outcome of an elevated removal, verified post-hoc (the script
/// itself is best-effort per command, so exit status alone proves nothing).
struct ElevatedRemovalOutcome {
    /// Paths verified gone from disk after the script ran.
    let removedPaths: Set<String>
    /// Package ids no longer listed by `pkgutil --pkgs`.
    let forgottenPackageIds: Set<String>
}

/// Removes root-owned files via osascript "with administrator privileges"
/// (native macOS password/Touch ID prompt). Items are moved into the real
/// user's Trash and chown-ed back to the user — never rm -rf — so they stay
/// recoverable. launchd jobs are booted out and pkg receipts forgotten in
/// the same script, so the user sees a single password prompt.
struct PrivilegedRemovalService {
    @discardableResult
    func removeElevated(paths: [URL],
                        bootoutLabels: [String] = [],
                        forgetPackageIds: [String] = []) async throws -> ElevatedRemovalOutcome {
        guard !paths.isEmpty || !bootoutLabels.isEmpty || !forgetPackageIds.isEmpty else {
            return ElevatedRemovalOutcome(removedPaths: [], forgottenPackageIds: [])
        }
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
        var parts: [String] = []
        if !paths.isEmpty {
            parts.append("mkdir -p \(shellQuote(trashDir))")
        }
        for label in bootoutLabels {
            parts.append("launchctl bootout system/\(shellQuote(label)) >/dev/null 2>&1 || true")
        }
        // Every command is individually best-effort: one failure must not
        // block the others, and results are verified afterwards anyway.
        for (index, path) in paths.enumerated() {
            let dest = "\(trashDir)/\(path.lastPathComponent)-\(stamp)-\(index)"
            parts.append("mv -f \(shellQuote(path.path)) \(shellQuote(dest)) || true")
            parts.append("chown -R \(shellQuote(user)) \(shellQuote(dest)) >/dev/null 2>&1 || true")
        }
        for packageId in forgetPackageIds {
            parts.append("pkgutil --forget \(shellQuote(packageId)) >/dev/null 2>&1 || true")
        }
        parts.append("true")
        try await ElevatedCommandRunner().run(parts.joined(separator: "; "))

        let removed = Set(paths.map(\.path).filter { !FileManager.default.fileExists(atPath: $0) })
        var forgotten = Set<String>()
        if !forgetPackageIds.isEmpty {
            let remaining = (try? await ProcessRunner.run("/usr/sbin/pkgutil", ["--pkgs"]))
                .map { Set($0.stdout.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }) }
                ?? []
            forgotten = Set(forgetPackageIds.filter { !remaining.contains($0) })
        }
        return ElevatedRemovalOutcome(removedPaths: removed, forgottenPackageIds: forgotten)
    }

    private func shellQuote(_ s: String) -> String {
        ElevatedCommandRunner.shellQuote(s)
    }
}
