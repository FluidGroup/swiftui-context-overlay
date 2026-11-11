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
    .package(
      url: "https://github.com/FluidGroup/swiftui-portal",
      revision: "bce6af07c329b2486721c8929d70d146c768c793"
    ),
  ],
  targets: [
    .target(
      name: "ContextOverlay",
      dependencies: [
        .product(name: "BackdropBlur", package: "swiftui-backdrop-blur"),
        .product(name: "Portal", package: "swiftui-portal"),
      ]
    ),
    .testTarget(name: "ContextOverlayTests", dependencies: ["ContextOverlay"])
  ],
  swiftLanguageModes: [.v6]
)
