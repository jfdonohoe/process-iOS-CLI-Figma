// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Lifts",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "Lifts"),
        .testTarget(name: "LiftsTests", dependencies: ["Lifts"]),
    ]
)
