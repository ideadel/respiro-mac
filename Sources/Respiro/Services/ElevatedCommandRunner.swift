import Foundation

/// Runs an arbitrary process and captures its output.
struct ProcessRunner {
    @discardableResult
    static func run(_ executable: String, _ arguments: [String]) async throws -> (status: Int32, stdout: String, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                // Drain both pipes while the child runs: reading only after
                // termination deadlocks once output exceeds the ~64KB pipe buffer.
                var stdoutData = Data()
                var stderrData = Data()
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }
                process.waitUntilExit()
                group.wait()
                continuation.resume(returning: (process.terminationStatus,
                                                String(data: stdoutData, encoding: .utf8) ?? "",
                                                String(data: stderrData, encoding: .utf8) ?? ""))
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
