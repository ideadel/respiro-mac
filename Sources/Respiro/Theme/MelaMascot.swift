import SwiftUI

/// "Mela" — the friendly MacBook mascot, built from SwiftUI shapes.
/// States: idle (slow breathing), scanning (pulsing rings + darting eyes),
/// happy (one bounce). Big on Smart Scan, 26 pt elsewhere.
struct MelaMascot: View {
    enum State { case idle, scanning, happy }

    var size: CGFloat = 96
    var state: State = .idle

    @SwiftUI.State private var breathe = false
    @SwiftUI.State private var ring = false
    @SwiftUI.State private var eyeShift: CGFloat = 0
    @SwiftUI.State private var bounce: CGFloat = 1

    private var screenGreen: Color { Color(lightHex: "0E5A34", darkHex: "0C5230") }
    private var laptopGreen: Color { Palette.accent }
    private var face: Color { .white }
    private var blush: Color { Color(lightHex: "34C87E", lightAlpha: 0.55, darkHex: "34C87E", darkAlpha: 0.6) }

    var body: some View {
        ZStack {
            if state == .scanning {
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(laptopGreen, lineWidth: size * 0.03)
                        .frame(width: size * 1.1, height: size * 1.1)
                        .scaleEffect(ring ? 1.3 : 1)
                        .opacity(ring ? 0 : 0.35)
                        .animation(.easeOut(duration: 2).repeatForever(autoreverses: false)
                            .delay(Double(i)), value: ring)
                }
            }
            mascot
                .scaleEffect(breathe ? 1.045 : 1)
                .scaleEffect(bounce)
        }
        .frame(width: size, height: size)
        .onAppear { start() }
        .onChange(of: state) { _ in start() }
    }

    private var mascot: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let unit = w / 100
            ZStack {
                // Laptop lid / screen
                RoundedRectangle(cornerRadius: 14 * unit, style: .continuous)
                    .fill(screenGreen)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14 * unit, style: .continuous)
                            .strokeBorder(laptopGreen, lineWidth: 6 * unit)
                    )
                    .frame(width: 74 * unit, height: 52 * unit)
                    .position(x: 50 * unit, y: 38 * unit)

                // Eyes
                Capsule().fill(face)
                    .frame(width: 8 * unit, height: 12 * unit)
                    .position(x: (39 + eyeShift) * unit, y: 36 * unit)
                Capsule().fill(face)
                    .frame(width: 8 * unit, height: 12 * unit)
                    .position(x: (61 + eyeShift) * unit, y: 36 * unit)

                // Blush cheeks
                Ellipse().fill(blush)
                    .frame(width: 9 * unit, height: 5 * unit)
                    .position(x: 36 * unit, y: 45 * unit)
                Ellipse().fill(blush)
                    .frame(width: 9 * unit, height: 5 * unit)
                    .position(x: 64 * unit, y: 45 * unit)

                // Smile
                Smile()
                    .stroke(face, style: StrokeStyle(lineWidth: 4 * unit, lineCap: .round))
                    .frame(width: 22 * unit, height: 10 * unit)
                    .position(x: 50 * unit, y: 46 * unit)

                // Keyboard deck / base
                Capsule().fill(laptopGreen)
                    .frame(width: 90 * unit, height: 10 * unit)
                    .position(x: 50 * unit, y: 70 * unit)

                // Sparkle
                Sparkle().fill(face)
                    .frame(width: 16 * unit, height: 16 * unit)
                    .position(x: 82 * unit, y: 16 * unit)
                    .opacity(0.95)
            }
        }
    }

    private func start() {
        breathe = false; bounce = 1; eyeShift = 0; ring = false
        withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
            breathe = true
        }
        switch state {
        case .scanning:
            ring = true
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                eyeShift = 2
            }
        case .happy:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { bounce = 1.12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { bounce = 1 }
            }
        case .idle:
            break
        }
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.8))
        return p
    }
}

private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2
        let waist = r * 0.32
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + waist, y: c.y - waist))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + waist, y: c.y + waist))
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - waist, y: c.y + waist))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - waist, y: c.y - waist))
        p.closeSubpath()
        return p
    }
}
