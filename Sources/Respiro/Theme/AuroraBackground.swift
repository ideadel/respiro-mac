import SwiftUI

/// Window background: flat base plus two soft radial "aurora" blobs.
struct AuroraBackground: View {
    /// Lower on list-heavy screens so glass cards stay readable.
    var subdued = false

    var body: some View {
        ZStack {
            Palette.windowBackground
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let strength: Double = subdued ? 0.45 : 1.0
                RadialGradient(colors: [Palette.auroraGreen.opacity(strength), .clear],
                               center: .topTrailing,
                               startRadius: 0, endRadius: max(w, h) * 0.75)
                RadialGradient(colors: [Palette.auroraBlue.opacity(strength), .clear],
                               center: .bottomLeading,
                               startRadius: 0, endRadius: max(w, h) * 0.7)
            }
        }
        .ignoresSafeArea()
    }
}
