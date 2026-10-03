# swiftui-context-overlay

ContextOverlay displays a live rendering of SwiftUI content in an overlay while keeping the original content mounted. The source keeps its state and animations; the destination mirrors its existing hosting view.

This package is independent of MessagingUI and has no external dependencies.

## Requirements

- iOS 17.0 or later
- Swift 6.0 or later

## Installation

Add the package and its `ContextOverlay` product:

```swift
dependencies: [
  .package(url: "https://github.com/FluidGroup/swiftui-context-overlay", branch: "main")
],
targets: [
  .target(
    name: "YourApp",
    dependencies: [
      .product(name: "ContextOverlay", package: "swiftui-context-overlay")
    ]
  )
]
```

## Usage

Place the source inside `ContextOverlayContainer`. A binding controls presentation, and the overlay builder receives SwiftUI's `TransitionPhase` for insertion and removal.

```swift
import ContextOverlay
import SwiftUI

struct CardScreen: View {
  @State private var isPresented = false

  var body: some View {
    ContextOverlayContainer {
      Text("Live content")
        .padding(24)
        .background(.blue, in: RoundedRectangle(cornerRadius: 20))
        .onTapGesture { isPresented = true }
        .contextOverlay(
          isEnabled: $isPresented,
          configuration: .init(backgroundBlurRadius: 16)
        ) { phase in
          VStack(spacing: 24) {
            PortalDestination(
              usesMatchedGeometry: phase != .identity,
              configuration: .init(
                allowsHitTesting: false,
                forwardsClientHitTestingToSourceView: false
              )
            )

            Button("Close") { isPresented = false }
              .opacity(phase.isIdentity ? 1 : 0)
          }
        }
    }
  }
}
```

The container blurs its content while an overlay is present. `backgroundBlurRadius` defaults to 16; set it to zero to keep the background sharp. Presentation and removal use `.smooth`.

`PortalDestination` keeps the source's dimensions. `usesMatchedGeometry` controls SwiftUI position matching; passing `phase != .identity` lets the destination move from the source on insertion and return on removal. Keep the source mounted through that removal transition.

Use one active source per container. The caller owns selection, gestures, destination layout, and controls.

## Native portal configuration

All native options can be supplied through `PortalDestination.Configuration`:

| Property | Default |
| --- | --- |
| `matchesAlpha` | `false` |
| `matchesTransform` | `false` |
| `matchesPosition` | `false` |
| `allowsHitTesting` | `true` |
| `forwardsClientHitTestingToSourceView` | `true` |
| `hidesSourceView` | `true` |

`configuration.matchesPosition` controls the native renderer and is independent of `usesMatchedGeometry`. Configuration changes apply to an existing destination. Removing the destination restores the source's drawing.

The renderer uses private UIKit API. A relocated SwiftUI source's buttons and gestures have not been shown to receive forwarded touches reliably. The example places the Close button in the overlay hierarchy and uses a display-only portal. UIKit hit-target tests verify a narrower contract than actual SwiftUI touch delivery.

## Development

Open `Package.swift` in Xcode to use the source previews. Run tests on an iOS Simulator:

```sh
xcodebuild test \
  -scheme swiftui-context-overlay \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## License

Apache License 2.0. The native portal implementation retains the MIT attribution from [FluidInterfaceKit](https://github.com/FluidGroup/FluidInterfaceKit/blob/main/Sources/FluidPortal/NativePortalView.swift) in its source file.
