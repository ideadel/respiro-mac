import Foundation

/// Runs an arbitrary process and captures its output.
struct ProcessRunner {
    @discardableResult
    static func run(_ executable: String, _ arguments: [String]) async throws -> (status: Int32, stdout: String, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            process.terminationHandler = { finished in
                let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                continuation.resume(returning: (finished.terminationStatus, stdout, stderr))
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

/// Runs a shell command as root via osascript "with administrator privileges"
/// (native macOS password/Touch ID prompt). Shared by PrivilegedRemovalService,
/// the maintenance tasks and system-level startup-item toggling.
struct ElevatedCommandRunner {
    func run(_ shellCommand: String) async throws {
        let appleScript = "do shell script \(Self.appleScriptQuote(shellCommand)) with administrator privileges"
        let (status, _, stderr) = try await ProcessRunner.run("/usr/bin/osascript", ["-e", appleScript])
        if status != 0 {
            if stderr.contains("-128") || stderr.lowercased().contains("user cancel") {
                throw ElevationError.userCancelled
            }
            throw ElevationError.scriptFailed(status: status, stderr: stderr)
        }
    }

    static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escapes for an AppleScript string literal (second quoting layer).
    static func appleScriptQuote(_ s: String) -> String {
        "\"" + s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            + "\""
    }
}
