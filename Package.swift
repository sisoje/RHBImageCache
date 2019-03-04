// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RHBImageCache",
    platforms: [
        //.macOS(.v10_12),
        .iOS("10.3"),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "RHBImageCache",
            targets: ["RHBImageCache"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/sisoje/RHBFoundation", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RHBImageCache",
            dependencies: ["RHBFoundation"],
            path: "Sources"
        ),
        .testTarget(
            name: "RHBImageCacheTests",
            dependencies: ["RHBImageCache"],
            path: "Tests"
        ),
    ]
)
