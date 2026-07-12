import SwiftUI

/// "Quale disco?" — the first choice of the Spazio area. One card per
/// mounted volume, with name, capacity bar and free space; the selection
/// drives Panorama and Zavorra.
struct VolumeBar: View {
    @ObservedObject var store: VolumeSelectionStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.volumes) { volume in
                    card(volume)
                }
            }
        }
    }

    private func card(_ volume: VolumeInfo) -> some View {
        let isSelected = store.selected?.url == volume.url
        let used = Double(volume.total - volume.free)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                store.selected = volume
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: volume.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.border)
                            Capsule().fill(isSelected ? Palette.accent : Palette.textSecondary.opacity(0.5))
                                .frame(width: max(2, proxy.size.width * used / Double(max(volume.total, 1))))
                        }
                    }
                    .frame(width: 110, height: 4)
                    Text("\(formatBytes(volume.free)) liberi di \(formatBytes(volume.total))")
                        .font(.system(size: 10))
                        .monospacedDigit()
                        .foregroundStyle(Palette.textSecondary)
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Palette.accentTint : Palette.sidebarGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent.opacity(0.5) : Palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(volume.isBootVolume ? "Il disco interno del Mac" : "Disco esterno")
    }
}
