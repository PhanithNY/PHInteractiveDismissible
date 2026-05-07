//
//  InteractivePopInteractionController.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public final class InteractivePopInteractionController: NSObject, InteractiveTransitioning {
  
  public var interactionInProgress = false
  /// Optional gate set by the `present(_:dismissalType:)` caller. Takes precedence over the protocol property.
  public var interactiveDismissShouldBegin: (() -> Bool)?
  private weak var viewController: InteractiveDismissible!
  private weak var transitionContext: UIViewControllerContextTransitioning?
  
  private var interactionDistance: CGFloat = 0
  private var interruptedTranslation: CGFloat = 0
  private var presentedFrame: CGRect?
  private var cancellationAnimator: UIViewPropertyAnimator?
  private var insertedPresentedViewController: Bool = false
  private var disabledInteractionViews: [UIView] = []
  
  // MARK: - Init
  
  public init(viewController: InteractiveDismissible) {
    self.viewController = viewController
    super.init()
    
    if let navigationController = viewController as? UINavigationController {
      // Keep the gesture attached even if the navigation stack changes.
      prepareGestureRecognizer(in: navigationController.view)
    } else {
      prepareGestureRecognizer(in: viewController.view)
    }
    
    if let scrollView = viewController.dismissibleScrollView {
      resolveScrollViewGestures(scrollView)
    }
  }
  
  private func prepareGestureRecognizer(in view: UIView) {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    gesture.delegate = self
    view.addGestureRecognizer(gesture)
    
    if let preferredCornerRadius = viewController.preferredCornerRadius, preferredCornerRadius > 0.0 {
      let targetView: UIView = (viewController as? UINavigationController)?.view ?? view
      targetView.layer.cornerRadius = preferredCornerRadius
      targetView.layer.masksToBounds = true
    }
  }
  
  private func resolveScrollViewGestures(_ scrollView: UIScrollView) {
    let scrollGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    scrollGestureRecognizer.delegate = self
    
    scrollView.addGestureRecognizer(scrollGestureRecognizer)
    scrollView.panGestureRecognizer.require(toFail: scrollGestureRecognizer)
  }
  
  // MARK: - Gesture handling
  
  @objc
  private func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard let superview = gestureRecognizer.view?.superview else {
      return
    }
    
    let translation = gestureRecognizer.translation(in: superview).x
    let velocity = gestureRecognizer.velocity(in: superview).x
    
    switch gestureRecognizer.state {
    case .began:
      gestureBegan()
      
    case .changed:
      gestureChanged(translation: translation + interruptedTranslation, velocity: velocity)
      
    case .cancelled:
      gestureCancelled(translation: translation + interruptedTranslation, velocity: velocity)
      
    case .ended:
      gestureEnded(translation: translation + interruptedTranslation, velocity: velocity)
      
    default:
      break
    }
  }
  
  private func gestureBegan() {
    disableOtherTouches()
    cancellationAnimator?.stopAnimation(true)
    
    if let presentedFrame = presentedFrame {
      interruptedTranslation = viewController.view.frame.minX - presentedFrame.minX
    }
    
    if !interactionInProgress {
      interactionInProgress = true
      viewController.dismiss(animated: true)
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if self.transitionContext == nil && self.interactionInProgress {
          self.resetInteractionState()
        }
      }
    }
  }
  
  private func gestureChanged(translation: CGFloat, velocity: CGFloat) {
    if translation < 0 {
      return
    }
    var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
    if progress < 0 { progress /= (1.0 + abs(progress * 20)) }
    update(progress: progress)
  }
  
  private func gestureCancelled(translation: CGFloat, velocity: CGFloat) {
    if transitionContext == nil {
      resetInteractionState()
      return
    }
    cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
  }
  
  private func gestureEnded(translation: CGFloat, velocity: CGFloat) {
    if transitionContext == nil {
      resetInteractionState()
      return
    }
    if velocity > 300 || (translation > interactionDistance / 2.0 && velocity > -300) {
      finish(initialSpringVelocity: springVelocity(distanceToTravel: interactionDistance - translation, gestureVelocity: velocity))
    } else {
      cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
    }
  }
  
  // MARK: - Transition controlling
  
  public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    presentedFrame = transitionContext.finalFrame(for: presentedViewController)
    self.transitionContext = transitionContext
    interactionDistance = transitionContext.containerView.bounds.width - presentedFrame.unsafelyUnwrapped.minX
  }
  
  private func update(progress: CGFloat) {
    guard let transitionContext = transitionContext,
      let presentedFrame = presentedFrame else {
        return
    }
    
    transitionContext.updateInteractiveTransition(progress)
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    presentedViewController.view.frame = CGRect(x: presentedFrame.minX + interactionDistance * progress, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
    
    // Make sure we call in only once per gesture
//    if !insertedPresentedViewController {
//      insertedPresentedViewController = true
//      DispatchQueue.main.async {
//        printIfDEBUG("Insertion")
//        transitionContext.containerView.insertSubview(presentingViewController.view, at: 0)
//      }
//    }
    
    let width: CGFloat = 0.25 * presentedFrame.width
    let originX: CGFloat = -((1 - progress) * width)
    presentingViewController.view.frame = CGRect(x: originX, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
    
    if let modalPresentationController = presentedViewController.presentationController as? PHModalPresentationController {
      modalPresentationController.fadeView.alpha = (1.0 - progress)/2
    }
  }
  
  private func cancel(initialSpringVelocity: CGFloat) {
    guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else {
      return
    }
    
    let finalPresentingFrame = CGRect(x: -(0.25 * presentedFrame.width), y: 0, width: presentedFrame.width, height: presentedFrame.height)
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    let timingParameters = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: initialSpringVelocity, dy: 0))
    cancellationAnimator = UIViewPropertyAnimator(duration: 0.35, timingParameters: timingParameters)
    
    cancellationAnimator?.addAnimations {
      presentingViewController.view.frame = finalPresentingFrame
      presentedViewController.view.frame = presentedFrame
      if let modalPresentationController = presentedViewController.presentationController as? PHModalPresentationController {
        modalPresentationController.fadeView.alpha = 0.50
      }
    }
    
    cancellationAnimator?.addCompletion { [weak self] _ in
      if Thread.isMainThread {
        transitionContext.cancelInteractiveTransition()
        transitionContext.completeTransition(false)
        self?.insertedPresentedViewController = false
        self?.interactionInProgress = false
        self?.enableOtherTouches()
      } else {
        DispatchQueue.main.async {
          transitionContext.cancelInteractiveTransition()
          transitionContext.completeTransition(false)
          self?.insertedPresentedViewController = false
          self?.interactionInProgress = false
          self?.enableOtherTouches()
        }
      }
    }
    
    cancellationAnimator?.startAnimation()
  }
  
  private func finish(initialSpringVelocity: CGFloat) {
    guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else { return }
    let presentedViewController = transitionContext.viewController(forKey: .from) as! InteractiveDismissible
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    
    let dismissedFrame = CGRect(x: transitionContext.containerView.bounds.width, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
    let timingParameters = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: initialSpringVelocity, dy: 0))
    let finishAnimator = UIViewPropertyAnimator(duration: 0.35, timingParameters: timingParameters)
    
    finishAnimator.addAnimations {
      presentingViewController.view.frame = CGRect(x: 0, y: 0, width: dismissedFrame.width, height: dismissedFrame.height)
      presentedViewController.view.frame = dismissedFrame
      if let modalPresentationController = presentedViewController.presentationController as? PHModalPresentationController {
        modalPresentationController.fadeView.alpha = 0.0
      }
    }
    
    finishAnimator.addCompletion { [weak self] _ in
      if Thread.isMainThread {
        transitionContext.finishInteractiveTransition()
        transitionContext.completeTransition(true)
        self?.interactionInProgress = false
        // Symmetric with the `cancel` completion. After a successful dismissal the presented VC
        // is usually gone, so this is harmless in the common case. The reason to call it is for
        // VC instances that are re-presented (caches, dependency-injected singletons): without
        // this, `disableOtherTouches`'s last snapshot stays applied and the next presentation
        // shows up with dead taps until something else flips `isUserInteractionEnabled` back.
        self?.enableOtherTouches()
      } else {
        DispatchQueue.main.async {
          transitionContext.finishInteractiveTransition()
          transitionContext.completeTransition(true)
          self?.interactionInProgress = false
          self?.enableOtherTouches()
        }
      }
    }
    
    finishAnimator.startAnimation()
  }
  
  // MARK: - Helpers
  
  private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
    distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
  }
  
  // Exposed at `internal` (rather than `private`) so the regression test for the idempotency
  // guard can invoke it directly via `@testable import`. Not part of the public surface.
  internal func disableOtherTouches() {
    // Idempotent: if we already hold a snapshot of views we disabled, return early. Without this
    // guard, a re-entry (a new pan starting mid spring-back via the resumption path —
    // `cancellationAnimator?.stopAnimation(true)` in `gestureBegan`) would re-snapshot
    // `subviews.filter(\.isUserInteractionEnabled)` — which is now empty because the originals
    // are still disabled — and clobber the references. The eventual `enableOtherTouches()`
    // would then restore nothing, leaving subviews stuck disabled and taps dead while the
    // pan recognizer (attached to `viewController.view` itself) keeps working.
    guard disabledInteractionViews.isEmpty else { return }
    disabledInteractionViews = viewController.view.subviews.filter(\.isUserInteractionEnabled)
    disabledInteractionViews.forEach {
      $0.isUserInteractionEnabled = false
    }
  }

  internal func enableOtherTouches() {
    disabledInteractionViews.forEach {
      $0.isUserInteractionEnabled = true
    }
    disabledInteractionViews.removeAll()
  }

  private func resetInteractionState() {
    interactionInProgress = false
    interruptedTranslation = 0
    enableOtherTouches()
  }
}

// MARK: - UIGestureRecognizerDelegate

extension InteractivePopInteractionController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let shouldBeginGate = interactiveDismissShouldBegin ?? viewController.interactiveDismissShouldBegin
    if let shouldBegin = shouldBeginGate, !shouldBegin() {
      return false
    }

    if let navigationController = viewController as? UINavigationController,
       navigationController.viewControllers.count > 1 {
      return false
    }

    if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view)
      let isRightwardPan = velocity.x > 0
      let isPrimarilyHorizontal = abs(velocity.x) > abs(velocity.y)
      guard isRightwardPan, isPrimarilyHorizontal else {
        return false
      }
    }
    
    if let scrollView = viewController.dismissibleScrollView {
      return scrollView.contentOffset.x <= 0
    }
    
    return true
  }
}
