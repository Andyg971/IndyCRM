// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IndyCrm",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "IndyCrm",
            targets: ["IndyCrm"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "IndyCrm",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ]
        )
    ]
)
