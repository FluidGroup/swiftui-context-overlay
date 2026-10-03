// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swiftui-context-overlay",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(name: "ContextOverlay", targets: ["ContextOverlay"])
  ],
  targets: [
    .target(name: "ContextOverlay"),
    .testTarget(name: "ContextOverlayTests", dependencies: ["ContextOverlay"])
  ],
  swiftLanguageModes: [.v6]
)
