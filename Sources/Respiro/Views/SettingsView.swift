import SwiftUI

struct SettingsView: View {
    @AppStorage(BackgroundScanScheduler.Keys.enabled) private var autoScanEnabled = false
    @AppStorage(BackgroundScanScheduler.Keys.intervalHours) private var intervalHours = 24
    @AppStorage(BackgroundScanScheduler.Keys.thresholdMB) private var thresholdMB = 1024
    @State private var launchAtLogin = BackgroundScanScheduler.shared.launchAtLoginEnabled
    @State private var launchAtLoginError: String?
    @State private var licenseKey = LicenseService.storedKey ?? ""
    @State private var licenseMessage: String?
    @State private var licenseOK = LicenseService.isLicensed
    @ObservedObject private var scheduler = BackgroundScanScheduler.shared

    var body: some View {
        Form {
            if LicenseService.requiresLicense {
                Section("Licenza") {
                    if licenseOK {
                        Label("Licenza attiva", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Palette.success)
                        if let key = LicenseService.storedKey {
                            Text(masked(key))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Button("Rimuovi licenza da questo Mac") {
                            LicenseService.deactivate()
                            licenseKey = ""
                            licenseOK = false
                        }
                    } else {
                        TextField("Chiave licenza", text: $licenseKey)
                            .font(.system(.body, design: .monospaced))
                        Button("Attiva") { activateLicense() }
                        if let licenseMessage {
                            Text(licenseMessage)
                                .font(.system(size: 11))
                                .foregroundStyle(licenseOK ? Palette.success : Palette.danger)
                        }
                        Link("Acquista su sevenweb.tv", destination: URL(string: "https://sevenweb.tv/apps/respiro/")!)
                    }
                }
            }

            Section("Accesso al disco") {
                if FullDiskAccessChecker.hasFullDiskAccess {
                    Label("Accesso completo al disco concesso", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Palette.success)
                } else {
                    Label("Accesso completo al disco non concesso", systemImage: "exclamationmark.circle")
                        .foregroundStyle(Palette.warning)
                    Text("Senza questo permesso alcune cartelle di sistema restano illeggibili: Respiro te lo dirà onestamente, senza fingere che tutto sia pulito.")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textSecondary)
                    Button("Apri Impostazioni di Sistema…") {
                        FullDiskAccessChecker.openSystemSettings()
                    }
                }
            }

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

    private func activateLicense() {
        if LicenseService.activate(licenseKey) {
            licenseOK = true
            licenseMessage = "Licenza attivata."
        } else {
            licenseOK = false
            licenseMessage = "Chiave non valida."
        }
    }

    private func masked(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count >= 3 else { return key }
        return "\(parts[0])-\(parts[1])-****-\(parts.last ?? "")"
    }
}
