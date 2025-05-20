// swift-tools-version: 5.9

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
            .upToNextMajor(from: "4.0.0")
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/yene/GCDWebServer",
            exact: "3.5.7"
        ),
    ],
    targets: [
        .target(
            name: "MuxPlayerSwift",
            dependencies: [
                .product(
                    name: "MUXSDKStats",
                    package: "mux-stats-sdk-avplayer"
                ),
                .product(
                    name: "GCDWebServer",
                    package: "GCDWebServer"
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
