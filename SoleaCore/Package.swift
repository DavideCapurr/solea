// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoleaCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SoleaCore", targets: ["SoleaCore"])
    ],
    targets: [
        .target(name: "SoleaCore"),
        .testTarget(name: "SoleaCoreTests", dependencies: ["SoleaCore"]),
    ]
)
