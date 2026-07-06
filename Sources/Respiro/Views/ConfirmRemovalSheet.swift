import SwiftUI

struct ConfirmRemovalSheet: View {
    let appName: String
    let itemCount: Int
    let totalSize: Int64
    let elevatedCount: Int
    var receiptCount: Int = 0
    var appIsRunning: Bool = false
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Disinstallare \(appName)?", systemImage: "trash")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Verranno spostati nel Cestino \(itemCount) file residui (\(LeftoverDetailView.formatBytes(totalSize))) più l'app stessa.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textPrimary)
                if elevatedCount > 0 {
                    Label("\(elevatedCount) elementi di sistema richiedono la password di amministratore.",
                          systemImage: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.warning)
                }
                if receiptCount > 0 {
                    Label("\(receiptCount) ricevute di installazione verranno dimenticate (pkgutil).",
                          systemImage: "doc.badge.gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                }
                if appIsRunning {
                    Label("\(appName) è in esecuzione e verrà chiusa prima della rimozione.",
                          systemImage: "power")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                }
                Text("Tutti gli elementi restano recuperabili dal Cestino.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }

            HStack {
                Spacer()
                Button("Annulla", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Disinstalla", role: .destructive, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Palette.windowBackground)
    }
}
