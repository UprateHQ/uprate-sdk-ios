// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UprateSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UprateSDK",
            targets: ["UprateSDK"]
        )
    ],
    targets: [
        .target(
            name: "UprateSDK",
            resources: [
                .copy("../../PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "UprateSDKTests",
            dependencies: ["UprateSDK"]
        )
    ],
    swiftLanguageModes: [.v6]
)
