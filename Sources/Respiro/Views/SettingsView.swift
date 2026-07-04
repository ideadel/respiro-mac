import SwiftUI

struct SettingsView: View {
    @AppStorage(BackgroundScanScheduler.Keys.enabled) private var autoScanEnabled = false
    @AppStorage(BackgroundScanScheduler.Keys.intervalHours) private var intervalHours = 24
    @AppStorage(BackgroundScanScheduler.Keys.thresholdMB) private var thresholdMB = 1024
    @State private var launchAtLogin = BackgroundScanScheduler.shared.launchAtLoginEnabled
    @State private var launchAtLoginError: String?
    @ObservedObject private var scheduler = BackgroundScanScheduler.shared

    var body: some View {
        Form {
            Section {
                Toggle("Avvia Respiro al login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            try BackgroundScanScheduler.shared.setLaunchAtLogin(newValue)
                            launchAtLoginError = nil
                        } catch {
                            launchAtLoginError = error.localizedDescription
                            launchAtLogin = BackgroundScanScheduler.shared.launchAtLoginEnabled
                        }
                    }
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.danger)
                }
            }

            Section("Scansione automatica") {
                Toggle("Scansiona in automatico", isOn: $autoScanEnabled)
                    .onChange(of: autoScanEnabled) { enabled in
                        if enabled { BackgroundScanScheduler.shared.start() }
                    }
                Picker("Frequenza", selection: $intervalHours) {
                    Text("Ogni giorno").tag(24)
                    Text("Ogni 3 giorni").tag(72)
                    Text("Ogni settimana").tag(168)
                }
                .disabled(!autoScanEnabled)
                Picker("Avvisami sopra", selection: $thresholdMB) {
                    Text("500 MB").tag(500)
                    Text("1 GB").tag(1024)
                    Text("5 GB").tag(5120)
                }
                .disabled(!autoScanEnabled)
                if let last = scheduler.lastResultDescription {
                    Text(last)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
                Text("La scansione avviene mentre Respiro è aperto (anche solo nella barra dei menu) e ti avvisa con una notifica quando c'è spazio da liberare.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }

            Section("Aggiornamenti") {
                if UpdaterService.shared.isActive {
                    Button("Controlla aggiornamenti…") {
                        UpdaterService.shared.checkForUpdates()
                    }
                } else {
                    Text("Aggiornamenti automatici non configurati in questa build (manca la chiave Sparkle).")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .navigationTitle("Impostazioni")
    }
}
