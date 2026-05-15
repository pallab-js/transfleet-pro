// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TransFleetPro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TransFleetPro",
            targets: ["TransFleetProApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.0")
    ],
    targets: [
        .executableTarget(
            name: "TransFleetProApp",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources"
        )
    ]
)