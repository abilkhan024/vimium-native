// swift-tools-version: 6.0

import PackageDescription

let appName = "VimiumNative";

let package = Package(
    name: appName,
    platforms: [
        .macOS(.v13) // Specify the minimum macOS version required
    ],
    products: [
        // This defines the app executable.
        .executable(
            name: appName,
            targets: [appName]
        )
    ],
    dependencies: [
        // Declare any external dependencies here.
        // Example: .package(url: "https://github.com/SomeLibrary/Library.git", from: "1.0.0")
    ],
    targets: [
        // The main app target.
        .executableTarget(
            name: appName,
            dependencies: [] // Add dependencies for this target
        )
    ]
)
