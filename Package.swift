// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BiometricAuthentication",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "BiometricAuthentication", targets: ["BiometricAuthentication"]),
    ],
    targets: [
        .target(
            name: "BiometricAuthentication",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "BiometricAuthenticationTests",
            dependencies: ["BiometricAuthentication"],
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
