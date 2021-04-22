// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "NetworkExtensions",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [.library(name: "NetworkExtensions", targets: ["NetworkExtensions"])],
    dependencies: [
        .package(url: "https://github.com/teufelaudio/FoundationExtensions.git", .upToNextMajor(from: "0.1.5"))
    ],
    targets: [
        .target(
            name: "NetworkExtensions",
            dependencies: [
                .product(name: "FoundationExtensions", package: "FoundationExtensions")
            ]
        ),
        .testTarget(name: "NetworkExtensionsTests", dependencies: ["NetworkExtensions"])
    ]
)
