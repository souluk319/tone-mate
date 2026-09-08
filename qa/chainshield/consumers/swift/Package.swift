// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToneMateRegistryConnection",
    dependencies: [.package(id: "tonemate.apple-audio", exact: "0.1.0-alpha.1")],
    targets: [.executableTarget(
        name: "ToneMateRegistryConnection",
        dependencies: [.product(name: "ToneMateAppleAudio", package: "tonemate.apple-audio")]
    )]
)
