import SwiftUI

struct RemovalResultView: View {
    let results: [RemovalResult]
    let banner: String?
    let appRemoved: Bool
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label(appRemoved ? "Disinstallazione completata" : "Disinstallazione parziale",
                      systemImage: appRemoved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(appRemoved ? Palette.success : Palette.warning)
                if let banner {
                    Text(banner)
                        .font(.callout)
                        .foregroundStyle(Palette.warning)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        HStack(spacing: 10) {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? Palette.success : Palette.danger)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.url.lastPathComponent)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Palette.textPrimary)
                                if let error = result.errorDescription {
                                    Text(error)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Palette.danger)
                                } else {
                                    Text(result.url.path)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Palette.textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, Metrics.cardPadding)
                        .padding(.vertical, 8)
                        if index < results.count - 1 {
                            Divider().overlay(Palette.border).padding(.leading, Metrics.cardPadding)
                        }
                    }
                }
            }
            .frame(maxHeight: 280)
            .glassCard()

            HStack {
                Button("Mostra nel Cestino") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/.Trash"))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accent)
                Spacer()
                Button("Fine", action: onClose)
                    .buttonStyle(.primaryCTA)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Metrics.windowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
