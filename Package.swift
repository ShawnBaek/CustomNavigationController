// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CustomNavigationController",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CustomNavigationController", targets: ["CustomNavigationController"])
    ],
    targets: [
        .target(name: "CustomNavigationController"),
        .testTarget(name: "CustomNavigationControllerTests", dependencies: ["CustomNavigationController"])
    ]
)
