// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GuandanCore",
    products: [
        .library(name: "GuandanCore", targets: ["GuandanCore"]),
    ],
    targets: [
        .target(name: "GuandanCore"),
        .executableTarget(name: "guandan-lab", dependencies: ["GuandanCore"]),
        .executableTarget(name: "guandan-web", dependencies: ["GuandanCore"]),
        .testTarget(name: "GuandanCoreTests", dependencies: ["GuandanCore"]),
    ]
)
