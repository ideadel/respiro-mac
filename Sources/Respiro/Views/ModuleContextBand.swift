import SwiftUI

/// Friendly context strip at the top of the main area — same height on every
/// section so the content below never jumps when you switch sidebar entries.
struct ModuleContextBand: View {
    let module: Module
    var compact: Bool

    var body: some View {
        HStack(spacing: 14) {
            iconBadge
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                if !compact {
                    Text(module.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                }
                Text(module.guidance)
                    .font(.system(size: compact ? 12 : 13))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(compact ? 1 : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.accentTint.opacity(compact ? 0.45 : 0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: 1)
        )
        .padding(.horizontal, Metrics.windowPadding)
        .padding(.top, compact ? 4 : 8)
        .padding(.bottom, 8)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.accent.opacity(0.14))
                .frame(width: compact ? 36 : 44, height: compact ? 36 : 44)
            Image(systemName: module.selectedIcon)
                .font(.system(size: compact ? 16 : 20, weight: .medium))
                .foregroundStyle(Palette.accent)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.accent.opacity(0.7))
                .offset(x: 4, y: -4)
        }
    }
}

/// Capsule tabs for sub-views inside one module (Diario, Zavorra).
struct SubModuleChipBar: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = index
                    }
                } label: {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selection == index ? Palette.accentTint : .clear)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(selection == index ? Palette.accent.opacity(0.4) : Palette.border,
                                              lineWidth: 1)
                        )
                        .foregroundStyle(selection == index ? Palette.accent : Palette.textSecondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, Metrics.windowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Metrics.subTabBandHeight)
    }
}
