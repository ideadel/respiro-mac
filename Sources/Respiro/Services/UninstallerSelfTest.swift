import Foundation

/// CLI self-test (`Respiro --selftest-uninstaller`): runs the real
/// LeftoverFinder against the fixture created by scripts/make-fixture.sh
/// and verifies every planted leftover is found. No XCTest — the machine
/// builds with SwiftPM + Command Line Tools only.
enum UninstallerSelfTest {
    static let fixtureBundleId = "com.respirotest.fixture"

    static func run() async -> Bool {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        // Pure-logic checks first (no filesystem needed).
        expect(LeftoverFinder.vendorToken(from: "com.respirotest.fixture") == "respirotest",
               "vendorToken: atteso 'respirotest'")
        expect(LeftoverFinder.vendorToken(from: "com.io.app") == nil,
               "vendorToken: token corto/stoplist deve dare nil")
        let zoom = InstalledApp(bundleIdentifier: "us.zoom.xos", displayName: "zoom.us",
                                bundleURL: URL(fileURLWithPath: "/Applications/zoom.us.app"), version: nil)
        expect(ReceiptService.matchReason(packageId: "us.zoom.pkg.videomeeting", app: zoom,
                                          vendorToken: "zoom") == .vendorMatch,
               "ReceiptService: ricevuta vendor Zoom non riconosciuta")
        expect(ReceiptService.matchReason(packageId: "com.apple.pkg.Safari", app: zoom,
                                          vendorToken: "zoom") == nil,
               "ReceiptService: i pacchetti Apple non devono mai matchare")

        let foo = InstalledApp(bundleIdentifier: "com.foo.app", displayName: "Team",
                               bundleURL: URL(fileURLWithPath: "/Applications/Team.app"), version: nil)
        expect(LeftoverFinder.matchReason(candidateName: "com.foo.app", app: foo,
                                          allowNameMatch: false) == .bundleIdExact,
               "match: bundle id esatto")
        expect(LeftoverFinder.matchReason(candidateName: "com.foo.app.plist", app: foo,
                                          allowNameMatch: false) == .bundleIdPrefix,
               "match: suffisso bundle id")
        expect(LeftoverFinder.matchReason(candidateName: "ABC123.com.foo.app", app: foo,
                                          allowNameMatch: false) == .bundleIdPrefix,
               "match: group container TEAMID.bundle")
        expect(LeftoverFinder.matchReason(candidateName: "backup-com.foo.app-old", app: foo,
                                          allowNameMatch: false) == nil,
               "match: substring nel mezzo non è un residuo")
        expect(LeftoverFinder.matchReason(candidateName: "mycom.foo.app.legacy", app: foo,
                                          allowNameMatch: false) == nil,
               "match: collisioni per contains() non devono matchare")
        expect(LeftoverFinder.matchReason(candidateName: "TeamViewer", app: foo,
                                          allowNameMatch: true) == .nameMatch,
               "match: solo nome resta disponibile")
        expect(MatchReason.nameMatch.shouldSelectByDefault == false,
               "nameMatch deve partire deselezionato")
        expect(MatchReason.vendorMatch.shouldSelectByDefault == false,
               "vendorMatch deve partire deselezionato")
        expect(MatchReason.bundleIdExact.shouldSelectByDefault,
               "bundleIdExact resta preselezionato")
        expect(ReceiptService.matchReason(packageId: "com.other.com.foo.app.extra", app: foo) == nil,
               "ReceiptService: contains() non deve matchare un package id estraneo")

        // Fixture app must exist.
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fixtureURL = home.appendingPathComponent("Applications/RespiroFixture.app", isDirectory: true)
        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            print("SELFTEST: fixture mancante — esegui prima scripts/make-fixture.sh create")
            return false
        }

        // The scanner must see it (also covers the one-level-descent fix).
        let apps = await AppScanner().scanInstalledApps()
        guard let app = apps.first(where: { $0.bundleIdentifier == fixtureBundleId }) else {
            print("SELFTEST: AppScanner non trova \(fixtureBundleId)")
            return false
        }

        // Helper ids read from the bundle.
        let auxIds = AppBundleInspector.auxiliaryBundleIds(of: app)
        expect(auxIds.contains("com.respirotest.helper"),
               "AppBundleInspector: LoginItem helper id non trovato")
        expect(auxIds.contains("com.respirotest.privhelper"),
               "AppBundleInspector: privileged helper (LaunchServices) non trovato")

        let items = await LeftoverFinder().findLeftovers(for: app, allApps: apps)
        let foundPaths = Set(items.map(\.url.path))

        // Every planted user-level leftover must be found.
        let expected = [
            "Library/Preferences/com.respirotest.fixture.plist",
            "Library/Preferences/ByHost/com.respirotest.fixture.ABC123.plist",
            "Library/Caches/com.respirotest.fixture",
            "Library/Caches/Respirotest",
            "Library/Application Support/RespiroFixture",
            "Library/Logs/com.respirotest.fixture.log",
            "Library/Logs/DiagnosticReports/RespiroFixture-2026-07-01-120000.ips",
            "Library/Saved Application State/com.respirotest.fixture.savedState",
            "Library/Containers/com.respirotest.fixture",
            "Library/Containers/com.respirotest.helper",
            "Library/Group Containers/ABC123.com.respirotest.fixture",
            "Library/LaunchAgents/respirotest-agent.plist",
            "Library/HTTPStorages/com.respirotest.fixture",
            "Library/WebKit/com.respirotest.fixture",
            "Library/Cookies/com.respirotest.fixture.binarycookies",
            "Library/Application Scripts/com.respirotest.fixture",
            "Library/Services/RespiroFixture Helper.workflow",
            "Library/QuickLook/RespiroFixture.qlgenerator",
            "Library/PreferencePanes/RespiroFixture.prefPane",
            "Library/Internet Plug-Ins/RespiroFixture.plugin",
            "Library/Audio/Plug-Ins/Components/RespiroFixture.component",
        ].map { home.appendingPathComponent($0).path }
        // Paths the fixture script couldn't plant (TCC-protected folders
        // without Full Disk Access) are skipped, not failed.
        var skipped = 0
        for path in expected {
            if !FileManager.default.fileExists(atPath: path) {
                skipped += 1
            } else if !foundPaths.contains(path) {
                failures.append("residuo non trovato: \(path)")
            }
        }
        if skipped > 0 {
            print("SELFTEST: \(skipped) percorsi saltati (non piantati dalla fixture, probabile TCC)")
        }

        // Negative controls: unrelated files must never match.
        let negatives = [
            "Library/Application Support/RespiroOther",
            "Library/Preferences/com.othervendor.unrelated.plist",
        ].map { home.appendingPathComponent($0).path }
        for path in negatives where foundPaths.contains(path) {
            failures.append("falso positivo: \(path)")
        }

        // The launchd agent must carry its label for the bootout step.
        let agent = items.first { $0.url.lastPathComponent == "respirotest-agent.plist" }
        expect(agent?.launchdLabel == "com.respirotest.fixture.agent",
               "LaunchAgent: label non catturata (\(agent?.launchdLabel ?? "nil"))")
        expect(agent?.launchdDomain == .userGui, "LaunchAgent: dominio atteso userGui")

        // Vendor matches must start unselected.
        let vendor = items.first { $0.url.lastPathComponent == "Respirotest" }
        expect(vendor?.matchReason == .vendorMatch, "Cartella vendor non marcata come vendorMatch")
        expect(vendor?.isSelected == false, "Vendor match deve partire deselezionato")

        let named = items.first { $0.url.lastPathComponent == "RespiroFixture" && $0.category == .appSupport }
        expect(named?.matchReason == .nameMatch, "Application Support matchato solo per nome")
        expect(named?.isSelected == false, "nameMatch deve partire deselezionato")

        if failures.isEmpty {
            print("SELFTEST OK — \(items.count) residui trovati, \(expected.count) attesi verificati")
            return true
        }
        print("SELFTEST FALLITO — \(failures.count) problemi:")
        for failure in failures { print("  ✗ \(failure)") }
        return false
    }
}
