// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Airis",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "airis", targets: ["Airis"]),
        .library(name: "AirisCore", targets: ["AirisCore"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.3.0"
        )
    ],
    targets: [
        .target(
            name: "AirisCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .executableTarget(
            name: "Airis",
            dependencies: ["AirisCore"]
        ),
        .testTarget(
            name: "AirisTests",
            dependencies: ["AirisCore"],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
