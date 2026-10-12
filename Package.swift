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
  dependencies: [
    .package(url: "https://github.com/FluidGroup/swiftui-backdrop-blur", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "ContextOverlay",
      dependencies: [
        .product(name: "BackdropBlur", package: "swiftui-backdrop-blur"),
      ]
    ),
    .testTarget(name: "ContextOverlayTests", dependencies: ["ContextOverlay"])
  ],
  swiftLanguageModes: [.v6]
)
