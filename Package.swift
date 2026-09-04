// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardRemapper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "keyboard-remapper",
            targets: ["KeyboardRemapper"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeyboardRemapper",
            dependencies: [],
            path: "Sources/KeyboardRemapper"
        )
    ]
)
