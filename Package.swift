// swift-tools-version: 5.9
// Package.swift — SPM dependency for RevenueCat
// Note: In an Xcode project, add via File → Add Package Dependencies instead

import PackageDescription

let package = Package(
    name: "PomoForge",
    platforms: [
        .iOS(.v18)
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "PomoForge",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "RevenueCatUI", package: "purchases-ios")
            ],
            path: "PomoForge"
        )
    ]
)
