// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoveMatch",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MoveMatch",
            targets: ["MoveMatch"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "MoveMatch",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ]),
        .testTarget(
            name: "MoveMatchTests",
            dependencies: ["MoveMatch"]),
    ]
)
