// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "iossim-mcp",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "iossim-mcp",
            dependencies: [
                "Core",
                .product(name: "MCP", package: "swift-sdk")
            ],
            resources: [
                .copy("Resources/SimDriverUITests-Runner.app"),
                .copy("Resources/SimDriverUITests_SimDriverUITests_iphonesimulator26.0-arm64.xctestrun")
            ]
        ),
        .target(
            name: "Core",
            dependencies: []
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        )
    ]
)
