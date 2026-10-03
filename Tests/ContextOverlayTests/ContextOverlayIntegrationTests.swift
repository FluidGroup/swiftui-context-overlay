import Observation
import SwiftUI
import Testing
import UIKit
@testable import ContextOverlay

/// Exercises the public overlay API with an original source mounted in a window.
@MainActor
@Suite(.serialized)
struct ContextOverlayIntegrationTests {
  @Test
  func sourceRemainsMountedWithoutADestination() async throws {
    let fixture = OverlayFixture()
    defer { fixture.close() }
    try await fixture.waitUntil { fixture.probe != nil }

    #expect(fixture.portal == nil)
    #expect(fixture.probe?.window === fixture.window)
  }

  @Test
  func presentationAndDismissalKeepTheOriginalRendering() async throws {
    let fixture = OverlayFixture()
    defer { fixture.close() }
    try await fixture.waitUntil { fixture.probe != nil }
    let originalProbe = try #require(fixture.probe)
    fixture.model.isPresented = true
    try await fixture.waitUntil { fixture.portal?.sourceView != nil }
    let portal = try #require(fixture.portal)
    let source = try #require(portal.sourceView)

    #expect(originalProbe.isDescendant(of: source))
    #expect(source.window === fixture.window)
    #expect(portal.hidesSourceView)

    fixture.model.isPresented = false
    try await fixture.waitUntil { fixture.portal == nil && portal.sourceView == nil }

    #expect(fixture.probe === originalProbe)
    #expect(originalProbe.window === fixture.window)
    #expect(!portal.hidesSourceView)
  }

  @Test
  func contentUpdatesTheSameSourceDuringPresentation() async throws {
    let fixture = OverlayFixture()
    defer { fixture.close() }
    try await fixture.waitUntil { fixture.probe != nil }
    fixture.model.isPresented = true
    try await fixture.waitUntil { fixture.portal?.sourceView != nil }
    let portal = try #require(fixture.portal)
    let originalSource = try #require(portal.sourceView)
    let originalProbe = try #require(fixture.probe)

    fixture.model.value = "updated"
    try await fixture.waitUntil { fixture.probe?.value == "updated" }

    #expect(fixture.portal === portal)
    #expect(portal.sourceView === originalSource)
    #expect(fixture.probe === originalProbe)
  }

  @Test
  func hostingInheritsEnvironmentAndItsUpdates() async throws {
    let fixture = OverlayFixture()
    defer { fixture.close() }
    try await fixture.waitUntil {
      fixture.probe?.localeIdentifier == "ja_JP"
        && fixture.probe?.environmentValue == "inherited"
    }
    let originalProbe = try #require(fixture.probe)

    fixture.model.localeIdentifier = "en_US"
    fixture.model.environmentValue = "updated-environment"
    try await fixture.waitUntil {
      fixture.probe?.localeIdentifier == "en_US"
        && fixture.probe?.environmentValue == "updated-environment"
    }

    #expect(fixture.probe === originalProbe)
  }
}

/// Owns the caller's presentation, content, and environment values during rendering.
@MainActor
@Observable
private final class OverlayModel {
  var isPresented = false
  var value = "original"
  var localeIdentifier = "ja_JP"
  var environmentValue = "inherited"
}

/// Keeps the UIKit host alive and waits for observable SwiftUI updates.
@MainActor
private final class OverlayFixture {
  let model = OverlayModel()
  let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
  private let hostingController: UIHostingController<AnyView>

  var probe: ContentProbe? { descendants(of: ContentProbe.self, in: window).first }
  var portal: NativePortalView? { descendants(of: NativePortalView.self, in: window).first }

  init() {
    hostingController = UIHostingController(
      rootView: AnyView(
        OverlayContent(model: model)
          .transaction {
            $0.animation = nil
            $0.disablesAnimations = true
          }
      )
    )
    window.rootViewController = hostingController
    window.isHidden = false
    window.layoutIfNeeded()
  }

  func waitUntil(_ predicate: @MainActor () -> Bool) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(3))
    while clock.now < deadline {
      window.setNeedsLayout()
      window.layoutIfNeeded()
      // Source publication is deferred from makeUIView to the next actor turn.
      // Allow that callback to run before observing readiness or changing binding.
      try await Task.sleep(for: .milliseconds(10))
      if predicate() { return }
    }
    #expect(predicate(), "The expected hosting update did not arrive")
    throw OverlayUpdateTimeout()
  }

  func close() {
    window.isHidden = true
    hostingController.rootView = AnyView(EmptyView())
    window.rootViewController = nil
  }
}

/// Presents a destination through the same Binding / builder API used by callers.
private struct OverlayContent: View {
  let model: OverlayModel

  var body: some View {
    ContextOverlayContainer {
      ProbeRepresentable(value: model.value)
        .frame(width: 120, height: 60)
        .contextOverlay(
          isEnabled: Binding(get: { model.isPresented }, set: { model.isPresented = $0 }),
          configuration: .init(backgroundBlurRadius: 0)
        ) { _ in
          PortalDestination(usesMatchedGeometry: false)
        }
    }
    .environment(\.locale, Locale(identifier: model.localeIdentifier))
    .environment(\.overlayTestValue, model.environmentValue)
  }
}

/// Makes the hosted view's identity, content, and inherited environment observable.
private struct ProbeRepresentable: UIViewRepresentable {
  let value: String

  func makeUIView(context: Context) -> ContentProbe { ContentProbe(frame: .zero) }

  func updateUIView(_ uiView: ContentProbe, context: Context) {
    uiView.value = value
    uiView.localeIdentifier = context.environment.locale.identifier
    uiView.environmentValue = context.environment.overlayTestValue
  }
}

/// A leaf view that must survive overlay insertion, updates, and removal.
@MainActor
private final class ContentProbe: UIView {
  var value = ""
  var localeIdentifier = ""
  var environmentValue = ""
}

extension EnvironmentValues {
  @Entry fileprivate var overlayTestValue = "default"
}

/// Identifies a missing rendering update instead of accepting a timing assumption.
private struct OverlayUpdateTimeout: Error {}

@MainActor
private func descendants<ViewType: UIView>(of type: ViewType.Type, in view: UIView) -> [ViewType] {
  let matches = (view as? ViewType).map { [$0] } ?? []
  return matches + view.subviews.flatMap { descendants(of: type, in: $0) }
}
