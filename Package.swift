// swift-tools-version: 6.0

import PackageDescription

let appName = "VimiumNative"

let package = Package(
  name: appName,
  platforms: [.macOS(.v13)],
  products: [.executable(name: appName, targets: [appName])],
  dependencies: [],
  targets: [
    .executableTarget(
      name: appName,
      dependencies: [],
      resources: [.embedInCode("Resources/DaemonTemplate.plist")],
    ),
  ],
  swiftLanguageModes: [.v6],
)
