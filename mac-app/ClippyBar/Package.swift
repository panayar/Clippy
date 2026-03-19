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
    targets: [
        .executableTarget(
            name: "ClippyBar",
            path: "Sources/ClippyBar",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
