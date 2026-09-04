// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ToneMateAppleAudio",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
    ],
    products: [
        .library(name: "ToneMateAppleAudio", targets: ["ToneMateAppleAudio"]),
    ],
    targets: [
        .target(name: "ToneMateAppleAudio"),
        .testTarget(
            name: "ToneMateAppleAudioTests",
            dependencies: ["ToneMateAppleAudio"]
        ),
    ]
)
