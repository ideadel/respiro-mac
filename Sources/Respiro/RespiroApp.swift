import SwiftUI
import AppKit

@main
struct RespiroApp: App {
    init() {
        SelfTestRunner.runIfRequested()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .task {
                    await CleaningHistoryStore.shared.snapshotFreeSpaceIfNeeded()
                    BackgroundScanScheduler.shared.start()
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                if UpdaterService.shared.isActive {
                    Button("Controlla aggiornamenti…") {
                        UpdaterService.shared.checkForUpdates()
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }

        MenuBarExtra {
            MenuBarView()
        } label: {
            MenuBarLabel()
        }
    }
}

/// The brand mascot silhouette as a template image (macOS tints it), falling
/// back to an SF Symbol if the bundled asset is missing.
struct MenuBarLabel: View {
    var body: some View {
        if let image = Self.templateGlyph {
            Image(nsImage: image)
        } else {
            Image(systemName: "sparkles")
        }
    }

    static let templateGlyph: NSImage? = {
        guard let url = Bundle.module.url(forResource: "menubar-glyph", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 22, height: 22)
        return image
    }()
}

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let stats = DiskUsageService.volumeStats() {
            Text("Spazio libero: \(formatBytes(stats.free)) di \(formatBytes(stats.total))")
        }
        Button("Apri Respiro") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Esci") { NSApp.terminate(nil) }
    }
}
