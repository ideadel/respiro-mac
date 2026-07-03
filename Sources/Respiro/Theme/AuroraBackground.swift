import SwiftUI

/// Window background: flat base plus two soft radial "aurora" blobs
/// (accent green top-right, cool blue bottom-left). These are what make the
/// glass materials read as glass rather than flat gray.
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Palette.windowBackground
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                RadialGradient(colors: [Palette.auroraGreen, .clear],
                               center: .topTrailing,
                               startRadius: 0, endRadius: max(w, h) * 0.75)
                RadialGradient(colors: [Palette.auroraBlue, .clear],
                               center: .bottomLeading,
                               startRadius: 0, endRadius: max(w, h) * 0.7)
            }
        }
        .ignoresSafeArea()
    }
}
