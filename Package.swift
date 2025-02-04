// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "NetworkExtensions",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(name: "NetworkExtensions", targets: ["NetworkExtensions"]),
        .library(name: "NetworkExtensionsDynamic", targets: ["NetworkExtensions"])
    ],
    dependencies: [
        .package(url: "https://github.com/teufelaudio/FoundationExtensions.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "NetworkExtensions",
            dependencies: [.product(name: "FoundationExtensions", package: "FoundationExtensions")]
        ),
        .target(
            name: "NetworkExtensionsDynamic",
            dependencies: [.product(name: "FoundationExtensionsDynamic", package: "FoundationExtensions")]
        ),
        .testTarget(name: "NetworkExtensionsTests", dependencies: ["NetworkExtensions"])
    ]
)
