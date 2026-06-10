// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GuandanCore",
    products: [
        .library(name: "GuandanCore", targets: ["GuandanCore"]),
    ],
    targets: [
        .target(name: "GuandanCore"),
        .testTarget(name: "GuandanCoreTests", dependencies: ["GuandanCore"]),
    ]
)
