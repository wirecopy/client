// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wirecopy",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WirecopyCore", targets: ["WirecopyCore"]),
        .executable(name: "WirecopyApp", targets: ["WirecopyMac"]),
        .executable(name: "WirecopyCLI", targets: ["WirecopyCLI"])
    ],
    targets: [
        .target(name: "WirecopyCore"),
        .executableTarget(
            name: "WirecopyMac",
            dependencies: ["WirecopyCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(name: "WirecopyCLI", dependencies: ["WirecopyCore"]),
        .testTarget(name: "WirecopyCoreTests", dependencies: ["WirecopyCore"])
    ]
)
