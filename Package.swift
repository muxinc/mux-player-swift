// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MuxAVPlayerSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MuxAVPlayerSDK",
            targets: ["MuxAVPlayerSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/mux-stats-sdk-avplayer",
            exact: "3.3.1"
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.2.0"
        ),
    ],
    targets: [
        .target(
            name: "MuxAVPlayerSDK",
            dependencies: [
                .product(
                    name: "MUXSDKStats",
                    package: "mux-stats-sdk-avplayer"
                )
            ]
        ),
        .testTarget(
            name: "MuxAVPlayerSDKTests",
            dependencies: [
                "MuxAVPlayerSDK"
            ]
        ),
    ]
)
