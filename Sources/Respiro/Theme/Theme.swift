import SwiftUI
import AppKit

// MARK: - Hex + dynamic light/dark colors

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }
}

extension Color {
    /// A color that resolves differently in light and dark appearance.
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    init(lightHex: String, lightAlpha: CGFloat = 1, darkHex: String, darkAlpha: CGFloat = 1) {
        self.init(light: NSColor(hex: lightHex, alpha: lightAlpha),
                  dark: NSColor(hex: darkHex, alpha: darkAlpha))
    }
}

// MARK: - Palette (Respiro Design Spec v2)

enum Palette {
    static let accent          = Color(lightHex: "1F9D58", darkHex: "34C87E")
    static let accentPressed   = Color(lightHex: "178B4C", darkHex: "43D68C")
    static let accentTint      = Color(lightHex: "DDF0E5", darkHex: "34C87E", darkAlpha: 0.16)
    static let windowBackground = Color(lightHex: "EFF4F1", darkHex: "171918")
    static let sidebarGlass    = Color(lightHex: "F7FAF8", lightAlpha: 0.60, darkHex: "171A18", darkAlpha: 0.60)
    static let cardGlass       = Color(lightHex: "FFFFFF", lightAlpha: 0.62, darkHex: "262A28", darkAlpha: 0.62)
    static let border          = Color(lightHex: "141E19", lightAlpha: 0.08, darkHex: "FFFFFF", darkAlpha: 0.09)
    static let textPrimary     = Color(lightHex: "1D1F1E", darkHex: "F1F4F2")
    static let textSecondary   = Color(lightHex: "6E7673", darkHex: "9BA39F")
    static let success         = Color(lightHex: "1F9D58", darkHex: "34C87E")
    static let warning         = Color(lightHex: "C4830F", darkHex: "E3A23C")
    static let danger          = Color(lightHex: "D0453E", darkHex: "E4635C")

    // Aurora blobs — the glass is only visible against these.
    static let auroraGreen     = Color(lightHex: "1F9D58", lightAlpha: 0.16, darkHex: "34C87E", darkAlpha: 0.20)
    static let auroraBlue      = Color(lightHex: "3E7BD6", lightAlpha: 0.12, darkHex: "4E86E0", darkAlpha: 0.16)
}

// MARK: - Metrics (8 pt grid)

enum Metrics {
    static let windowPadding: CGFloat = 24
    static let cardPadding: CGFloat = 15
    static let cardRadius: CGFloat = 12
    static let buttonRadius: CGFloat = 7
    static let rowHeight: CGFloat = 44
    static let sidebarMin: CGFloat = 180
    /// Space below traffic lights when using transparent title bar.
    static let titleBarSafeArea: CGFloat = 28
}

// MARK: - Reusable style pieces

/// The glass card recipe: regularMaterial in a rounded rect with a hairline border.
struct GlassCard: ViewModifier {
    var radius: CGFloat = Metrics.cardRadius
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(radius: CGFloat = Metrics.cardRadius) -> some View {
        modifier(GlassCard(radius: radius))
    }
}

/// Primary capsule CTA (accent-filled, dark-on-green text).
struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(configuration.isPressed ? Palette.accentPressed : Palette.accent, in: Capsule())
            .shadow(color: Palette.accent.opacity(configuration.isPressed ? 0.15 : 0.35), radius: 12, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryCTAStyle {
    static var primaryCTA: PrimaryCTAStyle { PrimaryCTAStyle() }
}
