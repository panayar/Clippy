// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClippyBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClippyBar", targets: ["ClippyBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/google/swift-benchmark.git", from: "0.1.2"),
    ],
    targets: [
        .target(
            name: "ClippyBarCore",
            path: "Sources/ClippyBarCore",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "ClippyBar",
            dependencies: ["ClippyBarCore"],
            path: "Sources/ClippyBar"
        ),
        .executableTarget(
            name: "Benchmarks",
            dependencies: [
                "ClippyBarCore",
                .product(name: "Benchmark", package: "swift-benchmark"),
            ],
            path: "Sources/Benchmarks"
        ),
    ]
)
