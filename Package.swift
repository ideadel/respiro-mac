// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Respiro",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Respiro",
            path: "Sources/Respiro",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
