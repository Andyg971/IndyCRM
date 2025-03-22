// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "IndyCRM",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "IndyCRM",
            targets: ["IndyCRM"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IndyCRM",
            dependencies: []
        ),
        .testTarget(
            name: "IndyCRMTests",
            dependencies: ["IndyCRM"]
        )
    ]
)