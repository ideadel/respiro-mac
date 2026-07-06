import AppKit
import SwiftUI

/// Shown on 2.0+ when no valid license is stored.
struct LicenseActivationView: View {
    var onActivated: () -> Void = {}
    @State private var key = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)
            MelaMascot(size: 96, state: .idle)
            Text("Attiva Respiro")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.textPrimary)
            Text("Inserisci la chiave di licenza ricevuta dopo l'acquisto. Una tantum, niente abbonamento.")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            TextField("RESPIRO-XXXX-XXXX-XX", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)
                .font(.system(.body, design: .monospaced))
            if let error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.danger)
            }
            Button("Attiva licenza") { activate() }
                .buttonStyle(.primaryCTA)
            Button("Acquista su sevenweb.tv") {
                if let url = URL(string: "https://sevenweb.tv/apps/respiro/") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.windowPadding)
        .background(AuroraBackground())
    }

    private func activate() {
        error = nil
        if LicenseService.activate(key) {
            onActivated()
        } else {
            error = "Chiave non valida. Controlla di averla copiata per intero."
        }
    }
}
