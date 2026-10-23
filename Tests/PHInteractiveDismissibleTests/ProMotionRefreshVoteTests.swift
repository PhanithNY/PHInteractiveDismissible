import UIKit
import XCTest
@testable import PHInteractiveDismissible

@MainActor
final class ProMotionRefreshVoteTests: XCTestCase {
  func testAutomaticDoesNotCreateADisplayLink() throws {
    let fixture = try Fixture()
    XCTAssertEqual(fixture.vote.preferredRate, .automatic)
    fixture.vote.setPreferredRate(.automatic)
    fixture.center.post(name: UIScene.didActivateNotification, object: fixture.scene)
    XCTAssertNil(fixture.vote.displayLink)
    XCTAssertEqual(fixture.recorder.creations, 0)
  }

  func testEveryManualRateReconfiguresTheSameLink() throws {
    let fixture = try Fixture()
    var originalLink: CADisplayLink?
    for rate in PHProMotionRefreshRate.allCases where rate != .automatic {
      fixture.vote.setPreferredRate(rate)
      let link = try XCTUnwrap(fixture.vote.displayLink)
      if let originalLink {
        XCTAssertTrue(link === originalLink)
      } else {
        originalLink = link
      }
      assertRate(rate.rawValue, on: link)
      XCTAssertFalse(link.isPaused)
    }
    fixture.vote.setPreferredRate(.fps60)
    assertRate(60, on: try XCTUnwrap(originalLink))
    XCTAssertEqual(fixture.recorder.creations, 1)
  }

  func testAutomaticPausesAndManualPreferenceResumesTheSameLink() throws {
    let fixture = try Fixture()
    fixture.vote.setPreferredRate(.fps120)
    let link = try XCTUnwrap(fixture.vote.displayLink)
    fixture.vote.setPreferredRate(.automatic)
    XCTAssertTrue(link.isPaused)
    fixture.center.post(name: UIScene.didActivateNotification, object: fixture.scene)
    XCTAssertTrue(link.isPaused, "Foregrounding must preserve automatic mode")
    fixture.vote.setPreferredRate(.fps90)
    XCTAssertFalse(link.isPaused)
    XCTAssertTrue(fixture.vote.displayLink === link)
    assertRate(90, on: link)
    XCTAssertEqual(fixture.recorder.creations, 1)
  }

  func testBackgroundPausesAndActivationRestoresLatestPreference() throws {
    let fixture = try Fixture()
    fixture.vote.setPreferredRate(.fps120)
    let link = try XCTUnwrap(fixture.vote.displayLink)
    for name in [UIScene.willDeactivateNotification, UIScene.didEnterBackgroundNotification,
          UIScene.didDisconnectNotification] {
      fixture.center.post(name: name, object: fixture.scene)
      XCTAssertTrue(link.isPaused)
      XCTAssertEqual(fixture.vote.preferredRate, .fps120)
      fixture.center.post(name: UIScene.didActivateNotification, object: fixture.scene)
      XCTAssertFalse(link.isPaused)
      assertRate(120, on: link)
    }
    fixture.center.post(name: UIScene.didEnterBackgroundNotification, object: fixture.scene)
    fixture.vote.setPreferredRate(.fps60)
    XCTAssertTrue(link.isPaused, "A preference change must not resume an inactive scene")
    fixture.center.post(name: UIScene.didActivateNotification, object: fixture.scene)
    XCTAssertFalse(link.isPaused)
    assertRate(60, on: link)
    XCTAssertEqual(fixture.recorder.creations, 1)
  }

  func testManualRequestWhileInactiveWaitsForActivation() throws {
    let fixture = try Fixture(isSceneActive: false)
    fixture.vote.setPreferredRate(.fps90)
    let link = try XCTUnwrap(fixture.vote.displayLink)
    XCTAssertTrue(link.isPaused)
    fixture.center.post(name: UIScene.willEnterForegroundNotification, object: fixture.scene)
    XCTAssertTrue(link.isPaused, "Entering foreground is not sufficient until the scene is active")
    fixture.center.post(name: UIScene.didActivateNotification, object: fixture.scene)
    XCTAssertFalse(link.isPaused)
    assertRate(90, on: link)
  }

  func testUnrelatedSceneNotificationsDoNotChangeTheVote() throws {
    let fixture = try Fixture()
    fixture.vote.setPreferredRate(.fps120)
    let link = try XCTUnwrap(fixture.vote.displayLink)
    fixture.center.post(name: UIScene.didEnterBackgroundNotification, object: NSObject())
    XCTAssertFalse(link.isPaused)
    fixture.center.post(name: UIScene.didEnterBackgroundNotification, object: fixture.scene)
    fixture.center.post(name: UIScene.didActivateNotification, object: NSObject())
    XCTAssertTrue(link.isPaused)
  }

  func testRatesClampToHardwareAndSupport60HzDisplays() throws {
    let fixture = try Fixture(maximumFPS: 60)
    fixture.vote.setPreferredRate(.fps120)
    let link = try XCTUnwrap(fixture.vote.displayLink)
    assertRate(60, on: link)
    XCTAssertFalse(link.isPaused)
    XCTAssertEqual(fixture.vote.preferredRate, .fps120, "Keep the caller's preference separate from hardware clamping")
    fixture.vote.setPreferredRate(.fps30)
    assertRate(30, on: link)
    XCTAssertEqual(fixture.recorder.creations, 1)
  }

  func testActivationReevaluatesDisplayCapabilities() throws {
    let scene = try activeScene()
    let center = NotificationCenter()
    var maximumFPS = 120
    let vote = ProMotionSceneRefreshVote(scene: scene, notificationCenter: center,
                      maximumFramesPerSecond: { _ in maximumFPS }, isSceneActive: true)
    vote.setPreferredRate(.fps120)
    let link = try XCTUnwrap(vote.displayLink)
    assertRate(120, on: link)
    center.post(name: UIScene.didEnterBackgroundNotification, object: scene)
    maximumFPS = 60
    center.post(name: UIScene.didActivateNotification, object: scene)
    assertRate(60, on: link)
    XCTAssertTrue(vote.displayLink === link)
  }

  func testFiveViewControllersInNavigationShareOneSceneLink() throws {
    let scene = try activeScene()
    let previous = scene.proMotionRefreshRate
    let window = UIWindow(windowScene: scene)
    let navigation = UINavigationController()
    window.rootViewController = navigation
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
      scene.proMotionRefreshRate = previous
    }
    var originalLink: CADisplayLink?
    let rates: [PHProMotionRefreshRate] = [.fps60, .fps120, .fps30, .fps90, .fps60]
    for rate in rates {
      let controller = UIViewController()
      navigation.pushViewController(controller, animated: false)
      navigation.view.layoutIfNeeded()
      XCTAssertTrue(controller.setProMotionRefreshRate(rate))
      let link = try XCTUnwrap(scene.proMotionRefreshVote?.displayLink)
      if let originalLink {
        XCTAssertTrue(link === originalLink)
      } else {
        originalLink = link
      }
      XCTAssertEqual(scene.proMotionRefreshRate, rate, "The latest assignment replaces the previous screen's preference")
    }
    XCTAssertEqual(navigation.viewControllers.count, 5)
    scene.proMotionRefreshRate = .automatic
    XCTAssertTrue(try XCTUnwrap(originalLink).isPaused)
    scene.proMotionRefreshRate = .fps120
    XCTAssertTrue(scene.proMotionRefreshVote?.displayLink === originalLink)
  }

  func testUnattachedControllerDoesNotLoadItsViewOrRetainItself() {
    weak var releasedController: UIViewController?
    autoreleasepool {
      let controller = UIViewController()
      releasedController = controller
      XCTAssertFalse(controller.setProMotionRefreshRate(.fps120))
      XCTAssertFalse(controller.isViewLoaded)
    }
    XCTAssertNil(releasedController)
  }

  func testSceneVoteDoesNotRetainAControllerThatSetsItsPreference() async throws {
    let scene = try activeScene()
    let previous = scene.proMotionRefreshRate
    defer { scene.proMotionRefreshRate = previous }
    let cleanup = expectation(description: "Attached controller deinitialized")
    weak var releasedController: UIViewController?
    autoreleasepool {
      let window = UIWindow(windowScene: scene)
      let controller = ReleaseObservingViewController()
      controller.onRelease = { cleanup.fulfill() }
      releasedController = controller
      // Attach the view without introducing UIWindow's root-controller appearance work.
      window.addSubview(controller.view)
      XCTAssertTrue(controller.setProMotionRefreshRate(.fps120))
      controller.view.removeFromSuperview()
    }
    // Wait for deinit instead of assuming UIKit finishes deferred work in one queue turn.
    await fulfillment(of: [cleanup], timeout: 3)
    XCTAssertNil(releasedController)
    XCTAssertEqual(scene.proMotionRefreshRate, .fps120, "Controller teardown must not change the manually controlled scene preference")
  }

  func testOwnerTeardownInvalidatesEvenAnExternallyRetainedLink() throws {
    let scene = try activeScene()
    let center = NotificationCenter()
    let recorder = DisplayLinkRecorder()
    weak var releasedVote: ProMotionSceneRefreshVote?
    weak var releasedTarget: NSObject?
    var retainedLink: CADisplayLink?
    autoreleasepool {
      var vote: ProMotionSceneRefreshVote? = ProMotionSceneRefreshVote(scene: scene,
        notificationCenter: center, makeDisplayLink: recorder.makeLink, isSceneActive: true)
      releasedVote = vote
      vote?.setPreferredRate(.fps120)
      retainedLink = vote?.displayLink
      releasedTarget = recorder.target
      XCTAssertNotNil(releasedTarget)
      vote = nil
    }
    XCTAssertNil(releasedVote, "The run-loop registration and notification observers must not retain their owner")
    XCTAssertNotNil(retainedLink)
    XCTAssertNil(releasedTarget, "Teardown must invalidate the link and release its target")
    center.post(name: UIScene.didActivateNotification, object: scene)
    XCTAssertEqual(recorder.creations, 1)
  }

  private func activeScene() throws -> UIWindowScene {
    try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
  }

  private func assertRate(_ expected: Int, on link: CADisplayLink,
    file: StaticString = #filePath, line: UInt = #line) {
    if #available(iOS 15.0, *) {
      XCTAssertEqual(link.preferredFrameRateRange.minimum, Float(expected), file: file, line: line)
      XCTAssertEqual(link.preferredFrameRateRange.maximum, Float(expected), file: file, line: line)
      XCTAssertEqual(link.preferredFrameRateRange.preferred, Float(expected), file: file, line: line)
    } else {
      XCTAssertEqual(link.preferredFramesPerSecond, expected, file: file, line: line)
    }
  }
}

private final class ReleaseObservingViewController: UIViewController {
  var onRelease: (() -> Void)?

  deinit { onRelease?() }
}

@MainActor
private final class Fixture {
  let scene: UIWindowScene
  let center = NotificationCenter()
  let recorder = DisplayLinkRecorder()
  let vote: ProMotionSceneRefreshVote

  init(maximumFPS: Int = 120, isSceneActive: Bool = true) throws {
    scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    vote = ProMotionSceneRefreshVote(scene: scene, notificationCenter: center,
      makeDisplayLink: recorder.makeLink, maximumFramesPerSecond: { _ in maximumFPS }, isSceneActive: isSceneActive)
  }
}

@MainActor
private final class DisplayLinkRecorder {
  private(set) weak var target: NSObject?
  private(set) var creations = 0

  func makeLink(scene: UIWindowScene, target: NSObject, selector: Selector) -> CADisplayLink? {
    self.target = target
    creations += 1
    return CADisplayLink(target: target, selector: selector)
  }
}
