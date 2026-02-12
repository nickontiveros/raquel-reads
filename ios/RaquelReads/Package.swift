// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RaquelReads",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "RaquelReadsCore",
            targets: ["RaquelReadsCore"]
        ),
    ],
    targets: [
        // Core library — models, services, utilities (no UI dependencies)
        .target(
            name: "RaquelReadsCore",
            path: "RaquelReads/RaquelReads",
            exclude: [
                "Views",
                "ViewModels",
                "Animations",
                "Widgets",
                "Resources",
                "RaquelReadsApp.swift",
            ],
            sources: [
                "Models",
                "Services",
                "Utilities",
            ]
        ),

        // Unit tests for core logic
        .testTarget(
            name: "RaquelReadsCoreTests",
            dependencies: ["RaquelReadsCore"],
            path: "Tests/RaquelReadsCoreTests"
        ),
    ]
)
