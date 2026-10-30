// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ClaudeLanes",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClaudeLanes", targets: ["ClaudeLanes"]),
    ],
    targets: [
        .target(name: "LanesCore"),
        .executableTarget(name: "ClaudeLanes", dependencies: ["LanesCore"]),
        .executableTarget(name: "LanesLauncher", dependencies: ["LanesCore"]),
        .testTarget(name: "LanesCoreTests", dependencies: ["LanesCore"]),
    ],
    swiftLanguageModes: [.v5]
)
