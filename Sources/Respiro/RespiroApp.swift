import SwiftUI
import AppKit

@main
struct RespiroApp: App {
    init() {
        SelfTestRunner.runIfRequested()
    }

    var body: some Scene {
        // Single-window scene: "Apri Respiro" re-focuses the existing window
        // instead of spawning a duplicate.
        Window("Respiro", id: "main") {
            ContentView()
                .task {
                    await CleaningHistoryStore.shared.snapshotFreeSpaceIfNeeded()
                    BackgroundScanScheduler.shared.start()
                }
        }
        .windowStyle(.hiddenTitleBar)
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
    @State private var snapshot = SystemMetricsService.snapshot()

    var body: some View {
        if let free = snapshot.diskFree, let total = snapshot.diskTotal {
            Text("Spazio libero: \(formatBytes(free)) di \(formatBytes(total))")
        }
        if let mem = snapshot.memory {
            Text("RAM disponibile: \(formatBytes(mem.availableBytes)) di \(formatBytes(mem.totalBytes))")
        }
        if let cpu = snapshot.cpuLoadPercent {
            Text(String(format: "CPU: %.0f%% carico medio", cpu))
        }
        Button("Apri Respiro") {
            // Bring the existing window forward; only create it if missing.
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: {
                $0.identifier?.rawValue.hasPrefix("main") == true
            }) {
                window.makeKeyAndOrderFront(nil)
            } else {
                openWindow(id: "main")
            }
        }
        .task {
            refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                refresh()
            }
        }
        Divider()
        Button("Esci") { NSApp.terminate(nil) }
    }

    private func refresh() {
        snapshot = SystemMetricsService.snapshot()
    }
}
