// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Lanes",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Lanes", targets: ["Lanes"]),
    ],
    targets: [
        .target(name: "LanesCore"),
        .executableTarget(name: "Lanes", dependencies: ["LanesCore"]),
        .executableTarget(name: "LanesLauncher", dependencies: ["LanesCore"]),
        .testTarget(name: "LanesCoreTests", dependencies: ["LanesCore"]),
    ],
    swiftLanguageModes: [.v5]
)
