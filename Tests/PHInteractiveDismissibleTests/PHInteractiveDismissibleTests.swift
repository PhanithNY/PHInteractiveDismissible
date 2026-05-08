import ObjectiveC.runtime
import UIKit
import XCTest
@testable import PHInteractiveDismissible

@MainActor
final class PHInteractiveDismissibleTests: XCTestCase {
  func testInteractiveTransitionManagerUsesAssociatedStorage() {
    let viewController = TestDismissibleViewController()
    let delegate = TestTransitioningDelegate()

    XCTAssertNil(viewController.interactiveTransitionManager)

    viewController.interactiveTransitionManager = delegate

    XCTAssertTrue(viewController.interactiveTransitionManager === delegate)
  }

  func testNavigationControllerForwardsInteractiveDismissibleProperties() {
    let rootViewController = TestDismissibleViewController()
    let scrollView = UIScrollView()
    rootViewController.configuredScrollView = scrollView
    rootViewController.configuredCornerRadius = 24

    let navigationController = UINavigationController(rootViewController: rootViewController)

    XCTAssertTrue(navigationController.dismissibleScrollView === scrollView)
    XCTAssertEqual(navigationController.preferredCornerRadius, 24)
  }

  func testPresentInteractiveConfiguresCustomTransition() {
    let presenter = CapturingPresenterViewController()
    let destination = TestDismissibleViewController()
    var completionCalled = false

    presenter.present(destination, dismissalType: .interactive, animated: false) {
      completionCalled = true
    }

    XCTAssertTrue(presenter.capturedPresentedViewController === destination)
    XCTAssertEqual(destination.modalPresentationStyle, .custom)
    XCTAssertTrue(destination.transitioningDelegate === destination.interactiveTransitionManager)
    XCTAssertTrue(destination.interactiveTransitionManager is PHModalTransitionManager)
    XCTAssertTrue(completionCalled)
  }

  func testZoomWithExplicitSourceRectConfiguresZoomTransition() {
    let presenter = CapturingPresenterViewController()
    let destination = ZoomTestNavigationController(rootViewController: ZoomTestViewController())
    let sourceView = UIView(frame: CGRect(x: 10, y: 20, width: 40, height: 50))
    let sourceRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    var completionCalled = false

    presenter.zoom(to: destination, from: sourceView, sourceRect: sourceRect) {
      completionCalled = true
    }

    XCTAssertTrue(presenter.capturedPresentedViewController === destination)
    XCTAssertEqual(destination.modalPresentationStyle, .custom)
    XCTAssertTrue(destination.transitioningDelegate === destination.interactiveTransitionManager)
    XCTAssertTrue(destination.interactiveTransitionManager is PHZoomTransitioningDelegate)
    XCTAssertEqual(destination._zoomTransitionSourceRect, sourceRect)
    XCTAssertTrue(destination._zoomTransitionSourceView === sourceView)
    XCTAssertTrue(destination._zoomTransitionSourceViewProvider?() === sourceView)
    XCTAssertTrue(completionCalled)
  }

  func testZoomWithInvalidSourceRectFallsBackToNilWhenSourceViewHasNoWindow() {
    let presenter = CapturingPresenterViewController()
    let destination = ZoomTestNavigationController(rootViewController: ZoomTestViewController())
    let sourceView = UIView(frame: CGRect(x: 10, y: 20, width: 40, height: 50))

    presenter.zoom(to: destination, from: sourceView, sourceRect: .zero)

    XCTAssertNil(destination._zoomTransitionSourceRect)
  }

  func testZoomInteractionBlocksPinchWhenNavigationStackHasMultipleViewControllers() {
    let rootViewController = ZoomTestViewController()
    let childViewController = ZoomTestViewController()
    let navigationController = ZoomTestNavigationController(rootViewController: rootViewController)
    navigationController.setViewControllers([rootViewController, childViewController], animated: false)

    let interactionController = PHZoomInteractivePopInteractionController(viewController: navigationController)
    let pinchGestureRecognizer = StubPinchGestureRecognizer()
    pinchGestureRecognizer.stubNumberOfTouches = 2

    XCTAssertFalse(interactionController.gestureRecognizerShouldBegin(pinchGestureRecognizer))
  }

  func testZoomInteractionAllowsPinchWhenNavigationStackHasSingleViewController() {
    let navigationController = ZoomTestNavigationController(rootViewController: ZoomTestViewController())
    let interactionController = PHZoomInteractivePopInteractionController(viewController: navigationController)
    let pinchGestureRecognizer = StubPinchGestureRecognizer()
    pinchGestureRecognizer.stubNumberOfTouches = 2

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(pinchGestureRecognizer))

    interactionController.interactionInProgress = true

    XCTAssertFalse(interactionController.gestureRecognizerShouldBegin(pinchGestureRecognizer))
  }

  func testZoomInteractionLazilyWiresDismissibleScrollViewGestures() {
    let viewController = ZoomTestViewController()
    let scrollView = UIScrollView()
    viewController.configuredScrollView = scrollView
    let interactionController = PHZoomInteractivePopInteractionController(viewController: viewController)
    let panGestureRecognizer = StubPanGestureRecognizer()
    panGestureRecognizer.stubVelocity = CGPoint(x: 100, y: 0)

    XCTAssertFalse(interactionController.isHorizontalDismissGestureWired(to: scrollView))
    XCTAssertFalse(interactionController.isVerticalDismissGestureWired(to: scrollView))

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))

    XCTAssertTrue(interactionController.isHorizontalDismissGestureWired(to: scrollView))
    XCTAssertTrue(interactionController.isVerticalDismissGestureWired(to: scrollView))
  }

  func testZoomInteractionRewiresReplacementTopScrollViewAfterSetViewControllers() {
    let originalViewController = ZoomTestViewController()
    let originalScrollView = UIScrollView()
    originalViewController.configuredScrollView = originalScrollView

    let replacementViewController = ZoomTestViewController()
    let replacementScrollView = UIScrollView()
    replacementViewController.configuredScrollView = replacementScrollView

    let navigationController = ZoomTestNavigationController(rootViewController: originalViewController)
    let interactionController = PHZoomInteractivePopInteractionController(viewController: navigationController)
    let panGestureRecognizer = StubPanGestureRecognizer()
    panGestureRecognizer.stubVelocity = CGPoint(x: 100, y: 0)

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))
    XCTAssertTrue(interactionController.isHorizontalDismissGestureWired(to: originalScrollView))
    XCTAssertTrue(interactionController.isVerticalDismissGestureWired(to: originalScrollView))
    XCTAssertFalse(interactionController.isHorizontalDismissGestureWired(to: replacementScrollView))
    XCTAssertFalse(interactionController.isVerticalDismissGestureWired(to: replacementScrollView))

    navigationController.setViewControllers([replacementViewController], animated: false)

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))
    XCTAssertTrue(interactionController.isHorizontalDismissGestureWired(to: replacementScrollView))
    XCTAssertTrue(interactionController.isVerticalDismissGestureWired(to: replacementScrollView))
  }

  func testZoomInteractionRepeatedGestureChecksDoNotChangeScrollViewRecognizerCount() {
    let viewController = ZoomTestViewController()
    let scrollView = UIScrollView()
    viewController.configuredScrollView = scrollView
    let interactionController = PHZoomInteractivePopInteractionController(viewController: viewController)
    let panGestureRecognizer = StubPanGestureRecognizer()
    panGestureRecognizer.stubVelocity = CGPoint(x: 100, y: 0)

    let initialGestureCount = scrollView.gestureRecognizers?.count ?? 0

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))
    let gestureCountAfterFirstCheck = scrollView.gestureRecognizers?.count ?? 0

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))
    let gestureCountAfterSecondCheck = scrollView.gestureRecognizers?.count ?? 0

    XCTAssertEqual(gestureCountAfterFirstCheck, initialGestureCount)
    XCTAssertEqual(gestureCountAfterSecondCheck, initialGestureCount)
  }

  func testZoomInteractionRejectsPanWhenInteractionInProgress() {
    let viewController = ZoomTestViewController()
    let interactionController = PHZoomInteractivePopInteractionController(viewController: viewController)
    let panGestureRecognizer = StubPanGestureRecognizer()
    panGestureRecognizer.stubVelocity = CGPoint(x: 100, y: 0)

    XCTAssertTrue(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))

    interactionController.interactionInProgress = true

    XCTAssertFalse(interactionController.gestureRecognizerShouldBegin(panGestureRecognizer))
  }

  func testZoomInteractionDoesNotLeakDisabledStateOnReentry() {
    let viewController = ZoomTestViewController()
    viewController.loadViewIfNeeded()
    let interactiveSubview = UIView()
    interactiveSubview.isUserInteractionEnabled = true
    viewController.view.addSubview(interactiveSubview)

    let interactionController = PHZoomInteractivePopInteractionController(viewController: viewController)

    // First "gesture begin" — snapshot taken, subview disabled.
    interactionController.disableOtherTouches()
    XCTAssertFalse(interactiveSubview.isUserInteractionEnabled,
                   "First disableOtherTouches must capture and disable the subview")

    // Re-entry — simulates a new gesture starting during the previous gesture's cancel/finish
    // animation. Without the idempotency guard, this re-snapshots `subviews.filter(...)`, which
    // is now empty (the subview is already disabled), and overwrites the references. The
    // subsequent `enableOtherTouches()` would then restore nothing.
    interactionController.disableOtherTouches()
    XCTAssertFalse(interactiveSubview.isUserInteractionEnabled,
                   "Re-entrant disableOtherTouches must not lose the snapshot — subview must remain disabled")

    interactionController.enableOtherTouches()
    XCTAssertTrue(interactiveSubview.isUserInteractionEnabled,
                  "enableOtherTouches must restore the subview — if it stays disabled, the snapshot was clobbered")
  }

  func testInteractivePopDoesNotLeakDisabledStateOnReentry() {
    let viewController = TestDismissibleViewController()
    viewController.loadViewIfNeeded()
    let interactiveSubview = UIView()
    interactiveSubview.isUserInteractionEnabled = true
    viewController.view.addSubview(interactiveSubview)

    let interactionController = InteractivePopInteractionController(viewController: viewController)

    // First "gesture begin" — snapshot taken, subview disabled.
    interactionController.disableOtherTouches()
    XCTAssertFalse(interactiveSubview.isUserInteractionEnabled,
                   "First disableOtherTouches must capture and disable the subview")

    // Re-entry — simulates a new pan starting mid spring-back via the resumption path. Without
    // the idempotency guard, this re-snapshots an empty filter (the subview is already
    // disabled) and overwrites the references; the subsequent `enableOtherTouches()` would
    // then restore nothing.
    interactionController.disableOtherTouches()
    XCTAssertFalse(interactiveSubview.isUserInteractionEnabled,
                   "Re-entrant disableOtherTouches must not lose the snapshot — subview must remain disabled")

    interactionController.enableOtherTouches()
    XCTAssertTrue(interactiveSubview.isUserInteractionEnabled,
                  "enableOtherTouches must restore the subview — if it stays disabled, the snapshot was clobbered")
  }

  func testInteractiveDismissGestureCancelKeepsPresentedViewController() {
    let harness = makeInteractiveDismissHarness()
    let gestureRecognizer = StubPanGestureRecognizer()
    harness.destinationViewController.view.addGestureRecognizer(gestureRecognizer)

    drivePanGesture(on: harness.interactionController,
                    gestureRecognizer: gestureRecognizer,
                    translationX: 40,
                    endVelocityX: 0)

    waitForTransitionCompletion(harness.transitionContext, timeout: 2.0)

    XCTAssertTrue(harness.transitionContext.cancelInteractiveTransitionCalled)
    XCTAssertEqual(harness.transitionContext.completedTransition, false)
    XCTAssertEqual(harness.destinationViewController.view.frame, harness.transitionContext.finalFrame)
  }

  func testInteractiveDismissGestureFinishDismissesPresentedViewController() {
    let harness = makeInteractiveDismissHarness()
    let gestureRecognizer = StubPanGestureRecognizer()
    harness.destinationViewController.view.addGestureRecognizer(gestureRecognizer)

    drivePanGesture(on: harness.interactionController,
                    gestureRecognizer: gestureRecognizer,
                    translationX: 320,
                    endVelocityX: 900)

    waitForTransitionCompletion(harness.transitionContext, timeout: 2.0)

    XCTAssertTrue(harness.transitionContext.finishInteractiveTransitionCalled)
    XCTAssertEqual(harness.transitionContext.completedTransition, true)
    XCTAssertEqual(harness.destinationViewController.view.frame.minX, harness.transitionContext.containerView.bounds.width)
  }
}

@MainActor
private final class CapturingPresenterViewController: UIViewController {
  private(set) var capturedPresentedViewController: UIViewController?

  override func present(_ viewControllerToPresent: UIViewController,
                        animated flag: Bool,
                        completion: (() -> Void)? = nil) {
    capturedPresentedViewController = viewControllerToPresent
    completion?()
  }
}

private final class TestDismissibleViewController: UIViewController, InteractiveDismissible {
  var configuredScrollView: UIScrollView?
  var configuredCornerRadius: CGFloat?

  var dismissibleScrollView: UIScrollView? {
    configuredScrollView
  }

  var preferredCornerRadius: CGFloat? {
    configuredCornerRadius
  }
}

private final class ZoomTestViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {
  var configuredScrollView: UIScrollView?

  var dismissibleScrollView: UIScrollView? {
    configuredScrollView
  }
}

private final class ZoomTestNavigationController: UINavigationController, ZoomTransitioning {}

private final class TestTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {}

@MainActor
private extension PHInteractiveDismissibleTests {
  struct InteractiveDismissHarness {
    let presenterViewController: UIViewController
    let destinationViewController: TestDismissibleViewController
    let interactionController: InteractivePopInteractionController
    let transitionContext: TestTransitionContext
  }

  func makeInteractiveDismissHarness(file: StaticString = #filePath,
                                     line: UInt = #line) -> InteractiveDismissHarness {
    let containerFrame = CGRect(x: 0, y: 0, width: 320, height: 640)
    let containerView = UIView(frame: containerFrame)
    let presenterViewController = UIViewController()
    let destinationViewController = TestDismissibleViewController()
    let finalFrame = CGRect(origin: .zero, size: containerFrame.size)
    let interactionController = InteractivePopInteractionController(viewController: destinationViewController)
    let transitionContext = TestTransitionContext(containerView: containerView,
                                                  fromViewController: destinationViewController,
                                                  toViewController: presenterViewController,
                                                  finalFrame: finalFrame)

    presenterViewController.loadViewIfNeeded()
    presenterViewController.view.frame = containerFrame
    destinationViewController.loadViewIfNeeded()
    destinationViewController.view.frame = finalFrame
    containerView.addSubview(presenterViewController.view)
    containerView.addSubview(destinationViewController.view)
    interactionController.startInteractiveTransition(transitionContext)
    interactionController.interactionInProgress = true

    XCTAssertNotNil(destinationViewController.view.superview, file: file, line: line)

    return InteractiveDismissHarness(presenterViewController: presenterViewController,
                                     destinationViewController: destinationViewController,
                                     interactionController: interactionController,
                                     transitionContext: transitionContext)
  }

  func drivePanGesture(on interactionController: InteractivePopInteractionController,
                       gestureRecognizer: StubPanGestureRecognizer,
                       translationX: CGFloat,
                       endVelocityX: CGFloat,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
    let handleSelector = NSSelectorFromString("handleGesture:")
    XCTAssertTrue(interactionController.responds(to: handleSelector), file: file, line: line)

    gestureRecognizer.setStubState(.began)
    gestureRecognizer.stubTranslation = .zero
    gestureRecognizer.stubVelocity = .zero
    interactionController.perform(handleSelector, with: gestureRecognizer)
    pumpRunLoop(for: 0.05)

    gestureRecognizer.setStubState(.changed)
    gestureRecognizer.stubTranslation = CGPoint(x: translationX, y: 0)
    interactionController.perform(handleSelector, with: gestureRecognizer)
    pumpRunLoop(for: 0.05)

    gestureRecognizer.setStubState(.ended)
    gestureRecognizer.stubTranslation = CGPoint(x: translationX, y: 0)
    gestureRecognizer.stubVelocity = CGPoint(x: endVelocityX, y: 0)
    interactionController.perform(handleSelector, with: gestureRecognizer)
  }

  func waitForTransitionCompletion(_ transitionContext: TestTransitionContext,
                                   timeout: TimeInterval,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
    let expectation = expectation(description: "wait for interactive transition completion")
    let deadline = Date().addingTimeInterval(timeout)

    func poll() {
      if transitionContext.completedTransition != nil {
        expectation.fulfill()
        return
      }

      if Date() >= deadline {
        expectation.fulfill()
        return
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        poll()
      }
    }

    poll()
    wait(for: [expectation], timeout: timeout + 0.5)
    XCTAssertNotNil(transitionContext.completedTransition, file: file, line: line)
  }

  func pumpRunLoop(for duration: TimeInterval) {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
      RunLoop.main.run(mode: .default, before: deadline)
    }
  }
}

private final class TestTransitionContext: NSObject, UIViewControllerContextTransitioning {
  let containerView: UIView
  let finalFrame: CGRect
  private let fromViewController: UIViewController
  private let toViewController: UIViewController

  var isAnimated: Bool = true
  var isInteractive: Bool = true
  var transitionWasCancelled: Bool = false
  var presentationStyle: UIModalPresentationStyle = .custom
  var targetTransform: CGAffineTransform = .identity
  var percentComplete: CGFloat = 0
  var completionVelocity: CGFloat = 0
  var completionCurve: UIView.AnimationCurve = .easeInOut

  private(set) var finishInteractiveTransitionCalled = false
  private(set) var cancelInteractiveTransitionCalled = false
  private(set) var completedTransition: Bool?

  init(containerView: UIView,
       fromViewController: UIViewController,
       toViewController: UIViewController,
       finalFrame: CGRect) {
    self.containerView = containerView
    self.fromViewController = fromViewController
    self.toViewController = toViewController
    self.finalFrame = finalFrame
  }

  func updateInteractiveTransition(_ percentComplete: CGFloat) {
    self.percentComplete = percentComplete
  }

  func finishInteractiveTransition() {
    finishInteractiveTransitionCalled = true
    transitionWasCancelled = false
  }

  func cancelInteractiveTransition() {
    cancelInteractiveTransitionCalled = true
    transitionWasCancelled = true
  }

  func pauseInteractiveTransition() {}

  func completeTransition(_ didComplete: Bool) {
    completedTransition = didComplete
  }

  func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
    switch key {
    case .from:
      fromViewController
    case .to:
      toViewController
    default:
      nil
    }
  }

  func view(forKey key: UITransitionContextViewKey) -> UIView? {
    viewController(forKey: key == .from ? .from : .to)?.view
  }

  func initialFrame(for vc: UIViewController) -> CGRect {
    vc.view.frame
  }

  func finalFrame(for vc: UIViewController) -> CGRect {
    vc === fromViewController ? finalFrame : containerView.bounds
  }
}

private final class StubPanGestureRecognizer: UIPanGestureRecognizer {
  var stubTranslation: CGPoint = .zero
  var stubVelocity: CGPoint = .zero

  func setStubState(_ state: UIGestureRecognizer.State,
                    file: StaticString = #filePath,
                    line: UInt = #line) {
    let selector = NSSelectorFromString("setState:")

    guard responds(to: selector),
          let method = class_getInstanceMethod(UIGestureRecognizer.self, selector) else {
      XCTFail("Unable to set gesture recognizer state for integration test", file: file, line: line)
      return
    }

    typealias Setter = @convention(c) (AnyObject, Selector, Int) -> Void
    let implementation = method_getImplementation(method)
    let function = unsafeBitCast(implementation, to: Setter.self)
    function(self, selector, state.rawValue)
  }

  override func translation(in view: UIView?) -> CGPoint {
    stubTranslation
  }

  override func velocity(in view: UIView?) -> CGPoint {
    stubVelocity
  }
}

private final class StubPinchGestureRecognizer: UIPinchGestureRecognizer {
  var stubNumberOfTouches = 0

  override var numberOfTouches: Int {
    stubNumberOfTouches
  }
}
