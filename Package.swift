// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Hypertext",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/thigcampos/syntax.git", branch: "main"),
        .package(url: "https://github.com/thigcampos/blueprint.git", branch: "main"),
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "hx",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Blueprint", package: "blueprint"),
                .product(name: "Syntax", package: "syntax"),
                .product(name: "Swifter", package: "swifter"),
            ]
        )
    ]
)
