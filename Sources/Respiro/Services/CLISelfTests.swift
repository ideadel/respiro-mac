import Foundation

/// Headless CLI checks (no XCTest). Invoked via flags on the Respiro binary.
enum DenyListSelfTest {
    static func run() -> Bool {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        expect(DenyList.isBlockedPath(URL(fileURLWithPath: "/System/Library")),
               "isBlockedPath: /System deve essere bloccato")
        expect(!DenyList.isBlockedPath(URL(fileURLWithPath: "/Library/Caches/test")),
               "isBlockedPath: /Library/Caches non è un prefisso bloccato")
        expect(DenyList.isBlockedBundleId("com.apple.Safari"),
               "isBlockedBundleId: bundle Apple bloccati")
        expect(!DenyList.isBlockedBundleId("com.example.app"),
               "isBlockedBundleId: bundle utente consentiti")

        let home = FileManager.default.homeDirectoryForCurrentUser
        let downloads = home.appendingPathComponent("Downloads/respiro-deny-test.txt")
        expect(DenyList.validateForRemoval(downloads),
               "validateForRemoval: file in Download consentito")
        expect(!DenyList.validateForRemoval(URL(fileURLWithPath: "/System/tmp/x")),
               "validateForRemoval: path di sistema negato")
        expect(!DenyList.validateForRemoval(home),
               "validateForRemoval: la home root non è rimovibile")

        let fixtureDir = home.appendingPathComponent("Downloads/.respiro-selftest", isDirectory: true)
        let target = fixtureDir.appendingPathComponent("target.txt")
        let link = fixtureDir.appendingPathComponent("link.txt")
        try? FileManager.default.createDirectory(at: fixtureDir, withIntermediateDirectories: true)
        try? "x".write(to: target, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(at: link)
        try? FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        defer { try? FileManager.default.removeItem(at: fixtureDir) }
        if FileManager.default.fileExists(atPath: link.path) {
            expect(DenyList.validateForRemoval(link),
                   "validateForRemoval: symlink sotto Download consentito")
        }

        if failures.isEmpty {
            print("SELFTEST denylist: OK (\(8) controlli)")
            return true
        }
        for message in failures { print("SELFTEST denylist FAIL: \(message)") }
        return false
    }
}

enum CleanupSelfTest {
    static func run() async -> Bool {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        let items = await JunkScanner().scan()
        let blocked = items.filter { DenyList.isBlockedPath($0.url) }
        expect(blocked.isEmpty,
               "JunkScanner: nessun path deny-listato (\(blocked.count) trovati)")

        let home = FileManager.default.homeDirectoryForCurrentUser
        let tmpFile = home.appendingPathComponent("Downloads/.respiro-cleanup-selftest.txt")
        do {
            try "fixture".write(to: tmpFile, atomically: true, encoding: .utf8)
            expect(DenyList.validateForRemoval(tmpFile),
                   "validateForRemoval: file in Download consentito")
        } catch {
            expect(false, "setup fixture Download: \(error.localizedDescription)")
        }
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        if failures.isEmpty {
            print("SELFTEST cleanup: OK")
            return true
        }
        for message in failures { print("SELFTEST cleanup FAIL: \(message)") }
        return false
    }
}

enum SelfTestRunner {
    static func runIfRequested() {
        let args = CommandLine.arguments
        if args.contains("--selftest-uninstaller") {
            Task.detached { exit(await UninstallerSelfTest.run() ? 0 : 1) }
            dispatchMain()
        }
        if args.contains("--selftest-denylist") {
            exit(DenyListSelfTest.run() ? 0 : 1)
        }
        if args.contains("--selftest-cleanup") {
            Task.detached { exit(await CleanupSelfTest.run() ? 0 : 1) }
            dispatchMain()
        }
    }
}
