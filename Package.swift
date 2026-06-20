// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LeafMark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LeafMark", targets: ["LeafMarkApp"]),
        .library(name: "LeafMarkCore", targets: ["LeafMarkCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "LeafMarkCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .executableTarget(
            name: "LeafMarkApp",
            dependencies: ["LeafMarkCore"]
        ),
        .testTarget(
            name: "LeafMarkCoreTests",
            dependencies: ["LeafMarkCore"]
        )
    ]
)
