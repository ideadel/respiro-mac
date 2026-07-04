// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Respiro",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Respiro",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Respiro",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                // Sparkle.framework is embedded in Contents/Frameworks by
                // build-app.sh; SwiftPM's own artifact rpath covers dev runs.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
