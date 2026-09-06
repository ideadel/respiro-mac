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

        let runningURL = Bundle.main.bundleURL
        expect(DenyList.isRunningApp(bundleURL: runningURL, bundleIdentifier: Bundle.main.bundleIdentifier),
               "isRunningApp: il bundle in esecuzione è riconosciuto")
        expect(!DenyList.isRunningApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"),
                                      bundleIdentifier: "com.apple.Safari"),
               "isRunningApp: altre app non sono il processo corrente")

        let extURL = URL(fileURLWithPath: "/tmp/com.foo.camera-extension")
        let userRoot = SearchRoots.all.first { !$0.isSystemLevel }!
        expect(LeftoverFinder.requiresElevation(for: extURL, root: userRoot),
               "requiresElevation: camera-extension richiede privilegi")

        let photos = home.appendingPathComponent("Pictures/Photos Library.photoslibrary")
        expect(DenyList.isBlockedPath(photos) || !DenyList.validateForRemoval(photos),
               "validateForRemoval: libreria Foto non è rimovibile")
        expect(!DenyList.validateForRemoval(home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")),
               "validateForRemoval: iCloud Drive non è rimovibile")
        expect(!DenyList.validateForRemoval(home.appendingPathComponent("Library/Keychains/login.keychain-db")),
               "validateForRemoval: portachiavi non è rimovibile")
        expect(!DenyList.validateForRemoval(home.appendingPathComponent(".ssh/id_ed25519")),
               "validateForRemoval: chiavi SSH non sono rimovibili")

        if failures.isEmpty {
            print("SELFTEST denylist: OK")
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
        let blocked = items.filter { DenyList.isBlockedPath($0.url) || !DenyList.validateForRemoval($0.url) }
        expect(blocked.isEmpty,
               "JunkScanner: nessun path deny-listato o non validabile (\(blocked.count) trovati)")

        let cautiousGroups = Set(["Stato applicazioni salvato", "Allegati Mail", "Archivi Xcode"])
        let wronglySelected = items.filter { cautiousGroups.contains($0.group) && $0.isSelected }
        expect(wronglySelected.isEmpty,
               "JunkScanner: gruppi da confermare non devono partire selezionati (\(wronglySelected.count))")

        expect(JunkScanner.shouldSkipCacheName("com.apple.bird") == true,
               "JunkScanner: cache iCloud (bird) esclusa")
        expect(JunkScanner.shouldSkipCacheName("com.apple.Photos") == true,
               "JunkScanner: cache Foto esclusa")
        expect(JunkScanner.shouldSkipCacheName("com.apple.Safari") == true,
               "JunkScanner: cache Safari Apple esclusa")
        expect(JunkScanner.shouldSkipCacheName("com.apple.HomeKit") == true,
               "JunkScanner: cache HomeKit esclusa")
        expect(JunkScanner.shouldSkipCacheName("familycircled") == true,
               "JunkScanner: familycircled escluso")
        expect(JunkScanner.shouldSkipCacheName("RespiroFixture-2026-07-01-120000.ips") == true,
               "JunkScanner: report della fixture escluso")
        expect(JunkScanner.shouldSkipCacheName("com.example.browser") == false,
               "JunkScanner: cache app normali restano visibili")
        expect(JunkScanner.isOfferable(URL(fileURLWithPath: "/tmp/respiro-does-not-exist-\(UUID().uuidString)")) == false,
               "JunkScanner: file inesistenti non si offrono")

        expect(JunkScanner.requiresElevation(for: URL(fileURLWithPath: "/Library/Caches/foo"),
                                             systemLevel: true),
               "JunkScanner: cache di sistema richiedono sempre privilegi")
        let humanized = RemovalErrorMessage.humanize("You don’t have permission to access some of the items.")
        expect(!humanized.contains("lucchetto"),
               "humanize: non deve chiedere il lucchetto in Aria")
        expect(RemovalErrorMessage.isPermissionFailure(humanized),
               "isPermissionFailure: riconosce l'errore di permesso")

        let home = FileManager.default.homeDirectoryForCurrentUser
        let mailDownload = home.appendingPathComponent(
            "Library/Containers/com.apple.mail/Data/Library/Mail Downloads/respiro-test.pdf")
        expect(DenyList.validateForRemoval(mailDownload),
               "validateForRemoval: allegati Mail Downloads restano consentiti")

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

enum AppScannerSelfTest {
    static func run() async -> Bool {
        let apps = await AppScanner().scanInstalledApps()
        let mainPath = Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL.path
        let mainId = Bundle.main.bundleIdentifier
        var failures: [String] = []
        for app in apps {
            if app.bundleURL.resolvingSymlinksInPath().standardizedFileURL.path == mainPath {
                failures.append("AppScanner: il bundle in esecuzione compare in lista (\(app.displayName))")
            }
            if let mainId, let id = app.bundleIdentifier, mainId.caseInsensitiveCompare(id) == .orderedSame {
                failures.append("AppScanner: stesso bundle ID del processo corrente (\(id))")
            }
        }
        if failures.isEmpty {
            print("SELFTEST appscanner: OK (\(apps.count) app, nessuna auto-rimozione)")
            return true
        }
        for message in failures { print("SELFTEST appscanner FAIL: \(message)") }
        return false
    }
}

enum SystemExtensionSelfTest {
    static func run() -> Bool {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        let sample = """
        4 extension(s)
        --- com.apple.system_extension.cmio
        enabled\tactive\tteamID\tbundleID (version)\tname\t[state]
        *\t*\t847R5ZLN8S\tcom.insta360.linkcontroller.camera-extension (1.0.46/46)\tcom.insta360.linkcontroller.camera-extension\t[activated enabled]
        """
        let parsed = SystemExtensionService.parseListOutput(sample)
        expect(parsed.count == 1, "parseListOutput: una riga attesa, trovate \(parsed.count)")
        if let row = parsed.first {
            expect(row.teamID == "847R5ZLN8S", "parseListOutput: teamID")
            expect(row.bundleID == "com.insta360.linkcontroller.camera-extension", "parseListOutput: bundleID")
            expect(row.isActive, "parseListOutput: stato attivo")
        }

        let artifact = URL(fileURLWithPath: "/Users/x/Library/Containers/com.foo.camera-extension")
        expect(SystemExtensionService.bundleId(fromExtensionArtifact: artifact) == "com.foo.camera-extension",
               "bundleId: container camera-extension")

        let ids = SystemExtensionService.bundleIds(
            from: [LeftoverItem(url: artifact, category: .containers, sizeBytes: nil,
                                isSelected: true, requiresElevation: true, matchReason: .bundleIdExact,
                                launchdLabel: nil, launchdDomain: nil)],
            auxiliaryIds: ["com.foo.helper"]
        )
        expect(ids == ["com.foo.camera-extension", "com.foo.helper"], "bundleIds: unione auxiliary + path")

        if failures.isEmpty {
            print("SELFTEST systemextension: OK (\(5) controlli)")
            return true
        }
        for message in failures { print("SELFTEST systemextension FAIL: \(message)") }
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
        if args.contains("--selftest-appscanner") {
            Task.detached { exit(await AppScannerSelfTest.run() ? 0 : 1) }
            dispatchMain()
        }
        if args.contains("--selftest-systemextension") {
            exit(SystemExtensionSelfTest.run() ? 0 : 1)
        }
    }
}
