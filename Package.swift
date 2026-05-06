// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-fakes",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Fakes",
            targets: ["Fakes"]
        ),
    ],
    traits: [
        "Nimble",
        .default(enabledTraits: ["Nimble"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "14.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Fakes",
            dependencies: [
                .product(
                    name: "Nimble",
                    package: "Nimble",
                    condition: .when(traits: ["Nimble"])
                ),
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "FakesTests",
            dependencies: ["Fakes", "Nimble"]
        ),
    ]
)
