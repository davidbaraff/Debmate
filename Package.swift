// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(watchOS)
let guiExclusions = ["Views_and_VCs", "SwiftUI"]
#else
let guiExclusions: [String] = []
#endif

/*
let testProgTarget = Target.executableTarget(name: "testProg",
                                            dependencies: ["Debmate"],
                                            path: "Sources/testProg")
*/

#if !os(Linux)
let packageDependencies: [Package.Dependency] = []
let libraryTargets = ["Debmate", "DebmateC"]
let targets: [Target] = [
    .target(
        name: "DebmateC",
        dependencies: [],
        path: "Sources/DebmateC"),
    .target(
        name: "Debmate",
        dependencies: ["DebmateC"],
        path: "Sources/Debmate",
        exclude: guiExclusions,
        resources: [.process("Resources")]),
    .testTarget(
        name: "DebmateTests",
        dependencies: ["Debmate"])
]
#else
let openCombine = Package.Dependency.package(url: "https://github.com/OpenCombine/OpenCombine.git",
                                           from: "0.13.0")
let swiftCrypto = Package.Dependency.package(url: "https://github.com/apple/swift-crypto.git",
                                            "1.0.0" ..< "3.0.0")
let packageDependencies: [Package.Dependency] = [openCombine, swiftCrypto]
let libraryTargets = ["Debmate", "CoreGraphics"]
let targets: [Target] = [
    .target(
        name: "Debmate",
        dependencies:  ["OpenCombine",
                        "DebmateLinuxQT",
                        "DebmateLinuxC",
                        .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                        .product(name: "OpenCombineShim", package: "OpenCombine"),
                        .product(name: "OpenCombineDispatch", package: "OpenCombine"),
                        .product(name: "Crypto", package: "swift-crypto")],
        path: "Sources/Debmate",
        exclude: ["Views_and_VCs",
                  "SwiftUI"],
        resources: [.process("Resources")]),
    .target(
        name: "DebmateLinuxQT",
        dependencies: [],
        path: "Sources/DebmateLinuxQT"),
    .target(
        name: "DebmateLinuxC",
        dependencies: [],
        path: "Sources/DebmateLinuxC"),
    .target(
        name: "CoreGraphics",
        dependencies: [],
        path: "Sources/CoreGraphics"),
    .testTarget(
        name: "DebmateTests",
        dependencies: ["Debmate"])
]
#endif

let package = Package(
    name: "Debmate",
    platforms: [.iOS(.v14),
                .tvOS(.v14),
                .watchOS(.v10),
                .macOS(.v11)],
    products: [
        .library(
            name: "Debmate",
            type: .dynamic,
            targets: libraryTargets),
    ],
    dependencies: packageDependencies,
    targets: targets /* + [testProgTarget] */
)
