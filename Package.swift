// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Airis",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "airis", targets: ["Airis"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.3.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Airis",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "AirisTests",
            dependencies: ["Airis"],
            resources: [
                .copy("../Resources")
            ]
        )
    ]
)
