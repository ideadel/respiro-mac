#!/usr/bin/env swift
/// Cattura screenshot di ogni sezione Respiro per il portale sevenweb.tv.
/// Uso: swift scripts/capture-screenshots.swift [cartella_output] [path/Respiro.app]
import AppKit
import CoreGraphics
import Foundation

func activate() {
    NSRunningApplication.runningApplications(withBundleIdentifier: "com.personal.Respiro").first?
        .activate(options: [.activateAllWindows])
}

func frame() -> (x: Int, y: Int, w: Int, h: Int)? {
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    guard let row = info.first(where: {
        ($0[kCGWindowOwnerName as String] as? String) == "Respiro"
            && ($0[kCGWindowLayer as String] as? Int ?? 99) == 0
            && (($0[kCGWindowBounds as String] as? [String: CGFloat])?["Width"] ?? 0) > 400
    }),
    let b = row[kCGWindowBounds as String] as? [String: CGFloat],
    let x = b["X"], let y = b["Y"], let w = b["Width"], let h = b["Height"] else { return nil }
    return (Int(x), Int(y), Int(w), Int(h))
}

func click(_ x: CGFloat, _ y: CGFloat) {
    let p = CGPoint(x: x, y: y)
    for t in [CGEventType.leftMouseDown, .leftMouseUp] {
        CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(50_000)
    }
}

func capture(name: String, outDir: URL) throws {
    guard let f = frame() else { throw NSError(domain: "cap", code: 1) }
    let path = outDir.appendingPathComponent("\(name).png").path
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-x", "-o", "-R\(f.x),\(f.y),\(f.w),\(f.h)", path]
    try task.run()
    task.waitUntilExit()
    print("ok \(name)")
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "sevenweb-portal/public/assets/screenshots")
let appPath = CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : "build/Respiro.app"

try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

if NSRunningApplication.runningApplications(withBundleIdentifier: "com.personal.Respiro").isEmpty {
    NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: appPath), configuration: .init()) { _, _ in }
    Thread.sleep(forTimeInterval: 3)
}

struct Shot { let name: String; let clicks: [(Int, Int)] }
let shots: [Shot] = [
    .init(name: "respira", clicks: []),
    .init(name: "spazio", clicks: [(130, 145)]),
    .init(name: "aria", clicks: [(130, 145), (310, 70)]),
    .init(name: "cestino", clicks: [(130, 145), (390, 70)]),
    .init(name: "zavorra", clicks: [(130, 145), (470, 70)]),
    .init(name: "panorama", clicks: [(130, 145), (550, 70)]),
    .init(name: "trasloco", clicks: [(130, 208)]),
    .init(name: "energia", clicks: [(130, 271)]),
    .init(name: "avvio", clicks: [(130, 271), (310, 70)]),
    .init(name: "tagliando", clicks: [(130, 271), (410, 70)]),
    .init(name: "guardia", clicks: [(130, 271), (530, 70)]),
    .init(name: "diario", clicks: [(130, 334)]),
]

for shot in shots {
    activate()
    Thread.sleep(forTimeInterval: 0.35)
    guard var f = frame() else { fputs("no window\n", stderr); exit(1) }
    for (dx, dy) in shot.clicks {
        click(CGFloat(f.x + dx), CGFloat(f.y + dy))
        Thread.sleep(forTimeInterval: 1.1)
        if let nf = frame() { f = nf }
    }
    try capture(name: shot.name, outDir: out)
}
