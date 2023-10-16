// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MuxPlayerSwift",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MuxPlayerSwift",
            targets: ["MuxPlayerSwift"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/muxinc/mux-stats-sdk-avplayer",
            exact: "3.4.1"
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.2.0"
        ),
    ],
    targets: [
        .target(
            name: "MuxPlayerSwift",
            dependencies: [
                .product(
                    name: "MUXSDKStats",
                    package: "mux-stats-sdk-avplayer"
                )
            ]
        ),
        .testTarget(
            name: "MuxPlayerSwiftTests",
            dependencies: [
                "MuxPlayerSwift"
            ]
        ),
    ]
)

