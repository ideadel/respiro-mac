import AppKit
import SwiftUI

/// Dynamic window chrome tint aligned with `Palette.windowBackground`.
enum RespiroWindowColors {
    static var background: NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(hex: "171918")
                : NSColor(hex: "EFF4F1")
        }
    }
}

/// Applies native transparent title bar + full-bleed content to the host window.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.scheduleConfigure(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.scheduleConfigure(for: nsView)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var configuredWindows = Set<ObjectIdentifier>()

        func scheduleConfigure(for view: NSView) {
            attemptConfigure(for: view, retries: 8)
        }

        private func attemptConfigure(for view: NSView, retries: Int) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                if let window = view.window {
                    self.apply(to: window)
                    return
                }
                guard retries > 0 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.attemptConfigure(for: view, retries: retries - 1)
                }
            }
        }

        private func apply(to window: NSWindow) {
            let id = ObjectIdentifier(window)
            guard !configuredWindows.contains(id) else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = RespiroWindowColors.background
            configuredWindows.insert(id)
        }
    }
}

private struct RespiroWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                WindowConfigurator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Palette.border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    /// Native macOS traffic lights over full-bleed content — no custom chrome.
    func respiroWindow() -> some View {
        modifier(RespiroWindowModifier())
    }
}
