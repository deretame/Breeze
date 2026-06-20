// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "aidoku-upscale-cli",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "AidokuUpscaleCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
