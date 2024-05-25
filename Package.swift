// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "autho",
    products: [
        .library(
            name: "autho",
            targets: ["autho"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ],
    targets: [
        .target(
            name: "autho",
            dependencies: [.product(name: "SQLite", package: "SQLite.swift")]
        ),
        .testTarget(
            name: "authoTests",
            dependencies: ["autho"]),
    ]
)
