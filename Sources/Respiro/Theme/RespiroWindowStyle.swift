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

/// Chromeless window: only traffic lights over full-bleed content.
enum RespiroWindowChrome {
    static func apply(to window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = RespiroWindowColors.background
        window.isMovableByWindowBackground = true
        window.contentMinSize = NSSize(width: 900, height: 560)
        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }
        if window.toolbar != nil {
            window.toolbar = nil
        }
    }
}

private final class ChromeApplyingView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        RespiroWindowChrome.apply(to: window)
        DispatchQueue.main.async { [weak window] in
            guard let window else { return }
            RespiroWindowChrome.apply(to: window)
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ChromeApplyingView(frame: .zero)
        context.coordinator.startObserving(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            RespiroWindowChrome.apply(to: window)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        private weak var view: NSView?

        func startObserving(_ view: NSView) {
            self.view = view
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(windowChanged(_:)),
                               name: NSWindow.didBecomeKeyNotification, object: nil)
            center.addObserver(self, selector: #selector(windowChanged(_:)),
                               name: NSWindow.didBecomeMainNotification, object: nil)
        }

        @objc private func windowChanged(_ notification: Notification) {
            guard let window = notification.object as? NSWindow,
                  window === view?.window else { return }
            RespiroWindowChrome.apply(to: window)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
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
    }
}

extension View {
    func respiroWindow() -> some View {
        modifier(RespiroWindowModifier())
    }
}
