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
  private var transitionContext: UIViewControllerContextTransitioning?
  
  private var interactionDistance: CGFloat = 0
  private var interruptedTranslation: CGFloat = 0
  private var presentedFrame: CGRect?
  private var cancellationAnimator: UIViewPropertyAnimator?
  private var finishAnimator: UIViewPropertyAnimator?
  private var insertedPresentedViewController: Bool = false
  private var disabledInteractionViews: [UIView] = []

  private enum InteractionResolution {
    case cancelled
    case finished
  }
  
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

  deinit {
    // Last line of defence: if the controller is torn down mid-interaction (e.g. the presented
    // VC is a cache/singleton whose views outlive this instance), restore any subviews we
    // disabled — otherwise they stay `isUserInteractionEnabled = false` with nothing left to fix them.
    enableOtherTouches()
  }

  private func prepareGestureRecognizer(in view: UIView) {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    gesture.delegate = self
    gesture.cancelsTouchesInView = true
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
    scrollGestureRecognizer.cancelsTouchesInView = true
    
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
      
    case .cancelled, .failed:
      gestureCancelled(translation: translation + interruptedTranslation, velocity: velocity)
      
    case .ended:
      gestureEnded(translation: translation + interruptedTranslation, velocity: velocity)
      
    default:
      break
    }
  }
  
  private func gestureBegan() {
    if completeInterruptedAnimatorIfNeeded() {
      return
    }

    disableOtherTouches()
    
    if let presentedFrame = presentedFrame {
      interruptedTranslation = viewController.view.frame.minX - presentedFrame.minX
    }
    
    if !interactionInProgress {
      interactionInProgress = true
      viewController.dismiss(animated: true)
    }

    // Safety net, scheduled on *every* `.began` (not just the first):
    // - If `dismiss(animated:)` didn't start a custom transition by the next run-loop tick,
    //   `transitionContext` stays nil — recover so `disableOtherTouches`'s snapshot doesn't strand.
    // - If a previous interaction wedged the controller (`interactionInProgress == true` with no
    //   live `transitionContext`), this re-arms the recovery the old single-shot version couldn't.
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if self.transitionContext == nil && self.interactionInProgress {
        self.resetInteractionState()
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
    // A very short gesture can end/cancel before UIKit calls this method. In that case the
    // controller has already reset; cancel the late context immediately so UIKit doesn't keep
    // an ownerless dismissal transition alive and block later presentations/dismissals.
    guard interactionInProgress else {
      transitionContext.cancelInteractiveTransition()
      transitionContext.completeTransition(false)
      return
    }

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
  
  // Exposed at `internal` so transition-completion tests can bypass private gesture state.
  internal func cancel(initialSpringVelocity: CGFloat) {
    guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else {
      // No live transition to wind down — but `disableOtherTouches()` already ran in
      // `gestureBegan`. Bailing without restoring is the dead-tap leak; reset instead.
      resetInteractionState()
      return
    }
    
    let finalPresentingFrame = CGRect(x: -(0.25 * presentedFrame.width), y: 0, width: presentedFrame.width, height: presentedFrame.height)
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    let timingParameters = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: initialSpringVelocity, dy: 0))
    let animations = {
      presentingViewController.view.frame = finalPresentingFrame
      presentedViewController.view.frame = presentedFrame
      if let modalPresentationController = presentedViewController.presentationController as? PHModalPresentationController {
        modalPresentationController.fadeView.alpha = 0.50
      }
    }

    guard transitionContext.isAnimated else {
      animations()
      completeInteraction(.cancelled)
      return
    }

    cancellationAnimator = UIViewPropertyAnimator(duration: 0.35, timingParameters: timingParameters)

    cancellationAnimator?.addAnimations(animations)
    
    cancellationAnimator?.addCompletion { [weak self] _ in
      self?.completeInteraction(.cancelled)
    }
    
    cancellationAnimator?.startAnimation()
  }
  
  // Exposed at `internal` so transition-completion tests can bypass private gesture state.
  internal func finish(initialSpringVelocity: CGFloat) {
    guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else {
      // See `cancel(initialSpringVelocity:)` — never leave `disabledInteractionViews` stranded.
      resetInteractionState()
      return
    }
    let presentedViewController = transitionContext.viewController(forKey: .from) as! InteractiveDismissible
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    
    let dismissedFrame = CGRect(x: transitionContext.containerView.bounds.width, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
    let timingParameters = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: initialSpringVelocity, dy: 0))
    let animations = {
      presentingViewController.view.frame = CGRect(x: 0, y: 0, width: dismissedFrame.width, height: dismissedFrame.height)
      presentedViewController.view.frame = dismissedFrame
      if let modalPresentationController = presentedViewController.presentationController as? PHModalPresentationController {
        modalPresentationController.fadeView.alpha = 0.0
      }
    }

    guard transitionContext.isAnimated else {
      animations()
      completeInteraction(.finished)
      return
    }

    finishAnimator = UIViewPropertyAnimator(duration: 0.35, timingParameters: timingParameters)

    finishAnimator?.addAnimations(animations)
    
    finishAnimator?.addCompletion { [weak self] _ in
      self?.completeInteraction(.finished)
    }
    
    finishAnimator?.startAnimation()
  }
  
  // MARK: - Helpers
  
  private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
    distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
  }

  @discardableResult
  internal func completeInterruptedAnimatorIfNeeded() -> Bool {
    if cancellationAnimator != nil {
      cancellationAnimator?.stopAnimation(true)
      completeInteraction(.cancelled)
      return true
    }

    if finishAnimator != nil {
      finishAnimator?.stopAnimation(true)
      completeInteraction(.finished)
      return true
    }

    return false
  }

  private func completeInteraction(_ resolution: InteractionResolution) {
    let completion = { [weak self] in
      guard let self else { return }
      guard let transitionContext = self.transitionContext else {
        self.resetInteractionState()
        return
      }

      switch resolution {
      case .cancelled:
        transitionContext.cancelInteractiveTransition()
        transitionContext.completeTransition(false)

      case .finished:
        transitionContext.finishInteractiveTransition()
        transitionContext.completeTransition(true)
      }

      self.transitionContext = nil
      self.resetInteractionState()
    }

    if Thread.isMainThread {
      completion()
    } else {
      DispatchQueue.main.async(execute: completion)
    }
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
    let viewsToDisable: [UIView]
    if let topViewController = (viewController as? UINavigationController)?.topViewController {
      viewsToDisable = topViewController.view.subviews.filter(\.isUserInteractionEnabled)
    } else {
      viewsToDisable = viewController.view.subviews.filter(\.isUserInteractionEnabled)
    }
    
    disabledInteractionViews = viewsToDisable //viewController.view.subviews.filter(\.isUserInteractionEnabled)
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
    transitionContext = nil
    insertedPresentedViewController = false
    interactionInProgress = false
    interruptedTranslation = 0
    interactionDistance = 0
    presentedFrame = nil
    cancellationAnimator = nil
    finishAnimator = nil
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

    if interactionInProgress, transitionContext == nil {
      resetInteractionState()
    }

    if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
      guard !interactionInProgress else { return false }
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
