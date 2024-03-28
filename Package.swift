// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swift-fakes",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        .library(
            name: "Fakes",
            targets: ["Fakes"]
        ),
    ],
    dependencies: [
        .package(url:  "https://github.com/Quick/Nimble.git", from: "13.2.1"),
    ],
    targets: [
        .target(
            name: "Fakes",
            dependencies: ["Nimble"],
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
