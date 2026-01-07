//
//  PHZoomInteractivePopInteractionController.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 25/12/25.
//

import UIKit

public final class PHZoomInteractivePopInteractionController: NSObject, InteractiveTransitioning {
  
  public var interactionInProgress = false
  private weak var viewController: (InteractiveDismissible & ZoomTransitioning)!
  private weak var transitionContext: UIViewControllerContextTransitioning?
  
  private var interactionDistance: CGFloat = 0
  private var interruptedTranslation: CGFloat = 0
  
  
  
  // MARK: - Init
  
  public init(viewController: InteractiveDismissible & ZoomTransitioning) {
    self.viewController = viewController
    super.init()
    
    if let viewController = (viewController as? UINavigationController)?.topViewController {
      prepareGestureRecognizer(in: viewController.view)
    } else {
      prepareGestureRecognizer(in: viewController.view)
    }
    
    if let scrollView = viewController.dismissibleScrollView {
      resolveScrollViewGestures(scrollView)
    }
  }
  
  private func prepareGestureRecognizer(in view: UIView) {
    let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    gesture.edges = .left
    view.addGestureRecognizer(gesture)
    
    if let preferredCornerRadius = viewController.preferredCornerRadius, preferredCornerRadius > 0.0 {
      let targetView: UIView = (viewController as? UINavigationController)?.view ?? view
      targetView.layer.cornerRadius = preferredCornerRadius
      targetView.layer.masksToBounds = true
    }
  }
  
  private func resolveScrollViewGestures(_ scrollView: UIScrollView) {
    let scrollGestureRecognizer = OneWayPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    scrollGestureRecognizer.direction = .left
    scrollGestureRecognizer.edges = scrollGestureRecognizer.direction.edges
    scrollGestureRecognizer.delegate = self
    
    scrollView.addGestureRecognizer(scrollGestureRecognizer)
    scrollView.panGestureRecognizer.require(toFail: scrollGestureRecognizer)
  }
  
  // MARK: - Gesture handling
  
  @objc
  private func handleGesture(_ gestureRecognizer: OneWayPanGestureRecognizer) {
    guard let superview = gestureRecognizer.view?.superview else {
      return
    }
    
    let translation = gestureRecognizer.translation(in: superview).x
    let translationY = gestureRecognizer.translation(in: superview).y
    let velocity = gestureRecognizer.velocity(in: superview).x
    
    switch gestureRecognizer.state {
    case .began:
      gestureBegan()
      
    case .changed:
      gestureChanged(translation: translation + interruptedTranslation, velocity: velocity, translationY: translationY)
      
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
    
    interruptedTranslation = 0
    
    if !interactionInProgress {
      interactionInProgress = true
      viewController.dismiss(animated: true)
    }
  }
  
  private func gestureChanged(translation: CGFloat, velocity: CGFloat, translationY: CGFloat) {
    if translation < 0 {
      return
    }
    var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
//    if progress < 0 { progress /= (1.0 + abs(progress * 20)) }
    progress = max(0, progress)
    update(progress: progress, translation: translation, translationY: translationY)
  }
  
  private func gestureCancelled(translation: CGFloat, velocity: CGFloat) {
    cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
  }
  
  private func gestureEnded(translation: CGFloat, velocity: CGFloat) {
    if velocity > 300 || (translation > interactionDistance / 2.0 && velocity > -300) {
      finish(initialSpringVelocity: springVelocity(distanceToTravel: interactionDistance - translation, gestureVelocity: velocity))
    } else {
      cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
    }
  }
  
  // MARK: - Transition controlling
  
  private func transitioningOptions(for context: UIViewControllerContextTransitioning) -> ZoomTransitioning.Options? {
    guard let fromView = context.viewController(forKey: .from)?.view,
          let toView = context.viewController(forKey: .to)?.view else {
      return nil
    }
    
    guard let toRect = context.sharedFrame(forKey: .to),
          let fromRect = context.sharedFrame(forKey: .from) else {
      return nil
    }
    
    return ZoomTransitioning.Options(fromView: fromView, fromRect: fromRect, toView: toView, toRect: toRect)
  }
  
  public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
    self.transitionContext = transitionContext
    interactionDistance = transitionContext.containerView.bounds.width //- presentedFrame.unsafelyUnwrapped.minX
    
    prepareLayouts()
  }
  
  private func update(progress: CGFloat, translation: CGFloat, translationY: CGFloat) {
    guard let transitionContext else {
        return
    }
    
    transitionContext.updateInteractiveTransition(progress)
    
//    guard let options = transitioningOptions(for: transitionContext) else {
//      return
//    }
//    
//    let fromView = options.fromView
//    let fromFrame = options.fromRect
//    let toView = options.toView
//    let toFrame = options.toRect
//    
//    let result = CGAffineTransform.transform(
//      parent: fromView.frame,
//      soChild: fromFrame,
//      aspectFills: toFrame
//    )
    
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    
    let scaleFactor: CGFloat = max(0.5, (1.0 - progress)) //* (1.0 - result.scaleFactor)
    print(presentedViewController.view.layer.cornerRadius)
    presentedViewController.view.transform = .init(translationX: translation, y: translationY).concatenating(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
//    presentedViewController.view.transform = result.transform
    print(scaleFactor, translation)
    
  }
  
  private func cancel(initialSpringVelocity: CGFloat) {
    guard let transitionContext else {
      return
    }
    
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    
    UIView.springAnimate(
      springDuration: 0.5,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: [.curveEaseInOut]) {
        presentingViewController.view.transform = .identity
        presentedViewController.view.transform = .identity
      } completion: { [weak self] finished in
        transitionContext.cancelInteractiveTransition()
        transitionContext.completeTransition(false)
        self?.interactionInProgress = false
        self?.enableOtherTouches()
      }
  }
  
  private func finish(initialSpringVelocity: CGFloat) {
    guard let transitionContext else { return }
    
    
    guard let options = transitioningOptions(for: transitionContext) else {
      transitionContext.completeTransition(false)
      return
    }
    
    let fromView = options.fromView
    let fromFrame = options.fromRect
    let toView = options.toView
    let toFrame = options.toRect
    
    let presentedViewController = transitionContext.viewController(forKey: .from) as! InteractiveDismissible
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    
    let result = CGAffineTransform.transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    UIView.springAnimate(
      springDuration: 0.5,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: [.curveEaseInOut]) {
        
        fromView.transform = result.transform
//        mask.frame = maskFrame
//        mask.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
//        overlay.layer.opacity = 0
//        dimmingView.effect = nil
//        snapshot.frame = maskFrame
//        snapshot.layer.cornerRadius = 0
//        blurView.contentView.backgroundColor = snapshot.backgroundColor
//        blurView.alpha = 1.0
        
      } completion: { [weak self] finished in
        transitionContext.finishInteractiveTransition()
        transitionContext.completeTransition(true)
        self?.interactionInProgress = false
        
        (presentingViewController as? ZoomTransitioning)?.config?.sourceView?.isHidden = false
      }
  }
  
  // MARK: - Helpers
  
  private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
    distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
  }
  
  private func disableOtherTouches() {
    viewController.view.subviews.forEach {
      $0.isUserInteractionEnabled = false
    }
  }
  
  private func enableOtherTouches() {
    viewController.view.subviews.forEach {
      $0.isUserInteractionEnabled = true
    }
  }
}

// MARK: - UIGestureRecognizerDelegate

extension PHZoomInteractivePopInteractionController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let scrollView = viewController.dismissibleScrollView {
      return scrollView.contentOffset.x <= 0
    }
    return true
  }
}

extension PHZoomInteractivePopInteractionController {
  private func prepareLayouts() {
    
    guard let transitionContext else {
      return
    }
    
    let presentedViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    print((presentedViewController as? ZoomTransitioning)?.config)
    guard let config = ((presentedViewController as? UINavigationController)?.topViewController as? ZoomTransitioning)?.config else {
      return
    }
    
    // Create and cache snapshot of the source view
    guard let sourceView = config.sourceView,
          let snapshot = sourceView.resizableSnapshotView(from: sourceView.bounds, afterScreenUpdates: false, withCapInsets: .zero) else {
      return
    }
    
    // Clone all available properties to new snapshot
    // Currently only background color and cornerRadius
    snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
    if let superviewBackgroundColor = snapshot.superview?.backgroundColor {
      snapshot.backgroundColor = sourceView.backgroundColor?.opaqueColor(over: superviewBackgroundColor)
    } else {
      snapshot.backgroundColor = sourceView.backgroundColor
    }
    
    // Save it to reuse later
//    self.sourceView = snapshot
    
    
    
    guard let options = transitioningOptions(for: transitionContext) else {
      transitionContext.completeTransition(false)
      return
    }
    
    let fromView = options.fromView
    let fromFrame = options.fromRect
    let toView = options.toView
    let toFrame = options.toRect
    
    let result = CGAffineTransform.transform(
      parent: toView.frame,
      soChild: toFrame,
      aspectFills: fromFrame
    )
    
    let transform = result.transform
    let maskFrame = fromFrame.aspectFit(to: toFrame)
    
    // Set frame for our snapshot view
    snapshot.frame = maskFrame
    
    // Represent the starting corner radius for our mask view
    let initialCornerRadius: CGFloat = snapshot.layer.cornerRadius / result.scaleFactor
    
    // Represent the final corner radius for our mask view
    let finalCornerRadius: CGFloat = config.maskCornerRadius
    
    let frame = transitionContext.containerView.bounds
    
    // Our mask view
    let mask = UIView(frame: frame).then {
      $0.backgroundColor = .black
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = initialCornerRadius
    }
    
    // Our overlay view
    let overlay = UIView().then {
      $0.backgroundColor = config.dimmingColor
      $0.layer.opacity = 0
      $0.frame = fromView.frame
    }
    
    // Our dimmingEffect view
    let dimmingView = makeDimmingVisualEffectView().then {
      $0.effect = nil
      $0.frame = toView.bounds
    }
    
    // Mask our target view
    toView.mask = mask
    toView.transform = transform
    
    // Add overlay view to our current view, fromView in this case
    fromView.addSubview(overlay)
    
    // Add blur view to our current view, fromView in this case
    fromView.addSubview(dimmingView)
    
    // Position snapshot to match the mask
    toView.addSubview(snapshot)
    
    // Create blur effect for morphing
    let maskVisualEffect = config.maskVisualEffect
    let blurView = UIVisualEffectView(effect: maskVisualEffect).then {
      $0.contentView.backgroundColor = snapshot.backgroundColor
      $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      $0.frame = toView.bounds
    }
    
    // Position blurView to match the mask
    toView.addSubview(blurView)
    
  }
  
  private func makeDimmingVisualEffectView() -> UIVisualEffectView {
    let presentedViewController = transitionContext!.viewController(forKey: .to).unsafelyUnwrapped as? ZoomTransitioning
    
    guard let config = presentedViewController!.config else {
      fatalError()
    }
    
    let effect = config.dimmingVisualEffect
    let view = UIVisualEffectView(effect: effect)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return view
  }
}
