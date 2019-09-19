// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BiometricAuthentication",
    platforms: [
        .iOS(.v8),
    ],
    products: [
        .library(name: "BiometricAuthentication", targets: ["BiometricAuthentication"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BiometricAuthentication",
            dependencies: [
            ],
            path: "BiometricAuthentication"
        )
    ],
    swiftLanguageVersions: [ .v5 ]
)
