// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Debmate",
    platforms: [.iOS(.v13),
                .macOS(.v10_15)],
    products: [
        .library(
            name: "Debmate",
            type: .dynamic,
            targets: ["Debmate", "DebmateC"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DebmateC",
            dependencies: [],
            path: "Sources/DebmateC"),
        .target(
            name: "Debmate",
            dependencies: ["DebmateC"],
            path: "Sources/Debmate",
            resources: [.process("Resources")]),
        .testTarget(
            name: "DebmateTests",
            dependencies: ["Debmate"]),
    ]
)
