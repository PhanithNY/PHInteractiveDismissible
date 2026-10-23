import ObjectiveC
import UIKit

/// A refresh-rate preference, subject to the display's capabilities and system policy.
public enum PHProMotionRefreshRate: Int, CaseIterable {
  /// Pause the refresh vote and let UIKit manage refresh without an additional request.
  case automatic = 0
  case fps30 = 30
  case fps60 = 60
  case fps90 = 90
  case fps120 = 120
}

public extension UIWindowScene {
  /// The scene's current preference. Defaults to `.automatic`.
  ///
  /// All controllers in this scene share one lazily created display link. Each assignment
  /// replaces the scene's preference; callers must restore it when navigating away.
  /// Inactivity pauses the link, and activation restores the selected preference.
  var proMotionRefreshRate: PHProMotionRefreshRate {
    get { proMotionRefreshVote?.preferredRate ?? .automatic }
    set {
      if let vote = proMotionRefreshVote {
        vote.setPreferredRate(newValue)
      } else if newValue != .automatic {
        let vote = ProMotionSceneRefreshVote(scene: self)
        objc_setAssociatedObject(self, &ProMotionRefreshAssociation.key, vote, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        vote.setPreferredRate(newValue)
      }
    }
  }
}

public extension UIViewController {
  /// Set the shared preference for this controller's attached scene.
  ///
  /// Call after attachment, for example in `viewDidAppear`. This does not remember a
  /// per-controller preference or restore it automatically when another screen leaves.
  /// Returns `false` if the view isn't attached to a scene, without loading the view.
  @discardableResult
  func setProMotionRefreshRate(_ rate: PHProMotionRefreshRate) -> Bool {
    guard let scene = viewIfLoaded?.window?.windowScene else { return false }
    scene.proMotionRefreshRate = rate
    return true
  }
}

extension UIWindowScene {
  var proMotionRefreshVote: ProMotionSceneRefreshVote? {
    objc_getAssociatedObject(self, &ProMotionRefreshAssociation.key) as? ProMotionSceneRefreshVote
  }
}

@MainActor
private enum ProMotionRefreshAssociation {
  static var key: UInt8 = 0
}

/// The scene owns this object; neither its display link nor its observers retain the scene.
@MainActor
final class ProMotionSceneRefreshVote: NSObject {
  typealias DisplayLinkFactory = @MainActor (UIWindowScene, NSObject, Selector) -> CADisplayLink?

  private weak var scene: UIWindowScene?
  private let notificationCenter: NotificationCenter
  private let makeDisplayLink: DisplayLinkFactory
  private let maximumFramesPerSecond: @MainActor (UIWindowScene) -> Int
  private var isSceneActive: Bool
  private(set) var preferredRate: PHProMotionRefreshRate = .automatic
  private(set) var displayLink: CADisplayLink?

  init(scene: UIWindowScene,
    notificationCenter: NotificationCenter = .default,
    makeDisplayLink: @escaping DisplayLinkFactory = { scene, target, selector in
      // Use the scene's screen so this source also builds with Xcode 26 SDKs.
      return scene.screen.displayLink(withTarget: target, selector: selector)
    },
    maximumFramesPerSecond: @escaping @MainActor (UIWindowScene) -> Int = { $0.screen.maximumFramesPerSecond },
    isSceneActive: Bool? = nil) {
    self.scene = scene
    self.notificationCenter = notificationCenter
    self.makeDisplayLink = makeDisplayLink
    self.maximumFramesPerSecond = maximumFramesPerSecond
    self.isSceneActive = isSceneActive ?? (scene.activationState == .foregroundActive)
    super.init()
    notificationCenter.addObserver(self, selector: #selector(sceneDidActivate(_:)),
                   name: UIScene.didActivateNotification, object: nil)
    for name in [UIScene.willDeactivateNotification, UIScene.didEnterBackgroundNotification,
          UIScene.didDisconnectNotification] {
      notificationCenter.addObserver(self, selector: #selector(sceneDidDeactivate(_:)), name: name, object: nil)
    }
  }

  deinit {
    notificationCenter.removeObserver(self)
    displayLink?.invalidate()
  }

  func setPreferredRate(_ rate: PHProMotionRefreshRate) {
    preferredRate = rate
    update()
  }

  private func update() {
    guard let scene, preferredRate != .automatic else {
      displayLink?.isPaused = true
      return
    }

    let link: CADisplayLink
    if let existing = displayLink {
      link = existing
    } else {
      // The target has no reference to this owner or any view controller.
      guard let created = makeDisplayLink(scene, TickTarget(), #selector(TickTarget.tick(_:))) else { return }
      link = created
      link.isPaused = true
      link.add(to: .main, forMode: .common)
      displayLink = link
    }

    let preferred = min(preferredRate.rawValue, max(1, maximumFramesPerSecond(scene)))
    if #available(iOS 15.0, *) {
      let rate = Float(preferred)
      link.preferredFrameRateRange = CAFrameRateRange(minimum: rate, maximum: rate, preferred: rate)
    } else {
      link.preferredFramesPerSecond = preferred
    }
    link.isPaused = !isSceneActive
  }

  @objc private func sceneDidActivate(_ notification: Notification) {
    guard let scene, let source = notification.object as? UIWindowScene, source === scene else { return }
    isSceneActive = true
    update()
  }

  @objc private func sceneDidDeactivate(_ notification: Notification) {
    guard let scene, let source = notification.object as? UIWindowScene, source === scene else { return }
    isSceneActive = false
    displayLink?.isPaused = true
  }

  private final class TickTarget: NSObject {
    // Registering the link supplies the vote; no drawing or screen polling is needed.
    @objc func tick(_ link: CADisplayLink) {}
  }
}
