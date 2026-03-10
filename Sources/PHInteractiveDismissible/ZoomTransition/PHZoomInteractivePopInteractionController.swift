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
  
  private weak var fromView: UIView?
  private weak var toView: UIView?
  private var config: ZoomOptions?
  private var resultTransform: CGAffineTransform = .identity
  private var resultScaleFactor: CGFloat = 1.0
  private var initialMaskFrame: CGRect = .zero
  private var finalMaskFrame: CGRect = .zero
  private var initialCornerRadius: CGFloat = 0
  private var finalCornerRadius: CGFloat = 0
  private var initialSnapshotCornerRadius: CGFloat = 0
  private var initialSnapshotFrame: CGRect = .zero
  
  private weak var maskView: UIView?
  private weak var overlayView: UIView?
  private weak var dimmingView: UIVisualEffectView?
  private weak var blurView: UIVisualEffectView?
  private weak var snapshotView: UIView?
  private weak var shadowView: UIView?
  private var sourceViewWasHidden: Bool = false
  
  // MARK: - Init
  
  public init(viewController: InteractiveDismissible & ZoomTransitioning) {
    self.viewController = viewController
    super.init()
    
    if let navigationController = viewController as? UINavigationController {
      prepareGestureRecognizer(in: navigationController.view)
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
    gesture.delegate = self
    view.addGestureRecognizer(gesture)
    
    if let navigationController = viewController as? UINavigationController,
       let popGesture = navigationController.interactivePopGestureRecognizer {
      popGesture.require(toFail: gesture)
    }
    
    if let preferredCornerRadius = viewController.preferredCornerRadius, preferredCornerRadius > 0.0 {
      let targetView: UIView = (viewController as? UINavigationController)?.view ?? view
      targetView.layer.cornerRadius = preferredCornerRadius
      targetView.layer.masksToBounds = true
    }
  }
  
  private func resolveScrollViewGestures(_ scrollView: UIScrollView) {
    let scrollGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    scrollGestureRecognizer.edges = .left
    scrollGestureRecognizer.delegate = self
    
    scrollView.addGestureRecognizer(scrollGestureRecognizer)
    scrollView.panGestureRecognizer.require(toFail: scrollGestureRecognizer)
  }
  
  // MARK: - Gesture handling
  
  @objc
  private func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
    guard let superview = gestureRecognizer.view?.superview else {
      return
    }
    
    let translation = gestureRecognizer.translation(in: superview).x
    let translationY = gestureRecognizer.translation(in: superview).y
    let velocity = gestureRecognizer.velocity(in: superview).x
    
    switch gestureRecognizer.state {
    case .began:
      print("PHZoomInteractivePopInteractionController gesture began")
      gestureBegan()
      
    case .changed:
      print("PHZoomInteractivePopInteractionController gesture changed")
      gestureChanged(translation: translation + interruptedTranslation, velocity: velocity, translationY: translationY)
      
    case .cancelled:
      print("PHZoomInteractivePopInteractionController gesture cancelled")
      gestureCancelled(translation: translation + interruptedTranslation, velocity: velocity)
      
    case .ended:
      print("PHZoomInteractivePopInteractionController gesture ended")
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
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if self.transitionContext == nil && self.interactionInProgress {
          self.resetInteractionState()
        }
      }
    }
  }
  
  private func gestureChanged(translation: CGFloat, velocity: CGFloat, translationY: CGFloat) {
    if translation < 0 {
      return
    }
    var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
    progress = max(0, min(1, progress))
    update(progress: progress, translation: translation, translationY: translationY)
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
    interactionDistance = transitionContext.containerView.bounds.width
    
    prepareLayouts()
  }
  
  private func update(progress: CGFloat, translation: CGFloat, translationY: CGFloat) {
    guard let transitionContext,
          let fromView,
          let maskView,
          let overlayView,
          let snapshotView else {
      return
    }

    transitionContext.updateInteractiveTransition(progress)

    let minimumScale = config?.minimumScale ?? 0.5
    var transform = clampedTransform(from: .identity, to: resultTransform, progress: progress, minimumScale: minimumScale)
    transform.ty = translationY
    transform = clampedTranslation(transform, in: transitionContext.containerView.bounds, for: fromView.bounds)
    fromView.transform = transform

    if let shadowView {
      let scale = hypot(transform.a, transform.c)
      let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
      shadowView.transform = transform
      shadowView.layer.shadowOpacity = Float(progress * 0.35)
      shadowView.layer.shadowPath = UIBezierPath(
        roundedRect: CGRect(origin: .zero, size: fromView.bounds.size),
        cornerRadius: cornerRadius / scale
      ).cgPath
    }
    
    let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
    maskView.frame = initialMaskFrame
    maskView.layer.cornerRadius = cornerRadius
    overlayView.layer.opacity = Float(1.0 - progress)
    dimmingView?.alpha = 1.0 - progress
     blurView?.alpha = progress
    snapshotView.frame = initialSnapshotFrame
    snapshotView.layer.cornerRadius = cornerRadius
    snapshotView.alpha = 0.0
  }
  
  private func cancel(initialSpringVelocity: CGFloat) {
    guard let transitionContext,
          let fromView,
          let maskView,
          let overlayView,
          let snapshotView else {
      return
    }

    UIView.springAnimate(
      springDuration: 0.5,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: [.curveEaseInOut]) {
        fromView.transform = .identity
        maskView.frame = self.initialMaskFrame
        maskView.layer.cornerRadius = self.initialCornerRadius
        overlayView.layer.opacity = 1.0
        self.dimmingView?.alpha = 1.0
        self.dimmingView?.effect = self.config?.dimmingVisualEffect
        self.blurView?.alpha = 0.0
        snapshotView.frame = self.initialSnapshotFrame
        snapshotView.layer.cornerRadius = self.initialCornerRadius
        self.shadowView?.transform = .identity
        self.shadowView?.layer.shadowOpacity = 0.0
      } completion: { [weak self] _ in
        transitionContext.cancelInteractiveTransition()
        transitionContext.completeTransition(false)
        self?.config?.sourceView?.isHidden = self?.sourceViewWasHidden ?? false
        self?.cleanUpTransitionViews()
        self?.resetInteractionState()
      }
  }
  
  private func finish(initialSpringVelocity: CGFloat) {
    guard let transitionContext,
          let fromView,
          let maskView,
          let overlayView,
          let snapshotView else { return }

    // Match non-interactive dismissal timing for snapshot crossfade (blur morph removed).
    let morphDuration = (config?.duration ?? 0.5) * 0.25
    let morphDelay = ((config?.maskVisualEffect == nil) ? (config?.duration ?? 0.5) * 0.3
                                                       : (config?.duration ?? 0.5) * 0.5)
    

    UIView.springAnimate(
      springDuration: 0.5,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: [.curveEaseInOut]) {
        fromView.transform = self.resultTransform
        maskView.frame = self.finalMaskFrame
        maskView.layer.cornerRadius = self.finalCornerRadius / self.resultScaleFactor
        overlayView.layer.opacity = 0.0
        self.dimmingView?.alpha = 0.0
        self.dimmingView?.effect = nil
        snapshotView.frame = self.finalMaskFrame
        snapshotView.layer.cornerRadius = self.finalCornerRadius / self.resultScaleFactor
        self.blurView?.alpha = 1.0
        self.shadowView?.transform = self.resultTransform
        self.shadowView?.layer.shadowOpacity = 0.0
      } completion: { [weak self] _ in
        transitionContext.finishInteractiveTransition()
        transitionContext.completeTransition(true)
        self?.config?.sourceView?.isHidden = false
        self?.cleanUpTransitionViews()
        self?.resetInteractionState()
      }
    
    UIView.springAnimate(
      springDuration: morphDuration,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: morphDelay,
      options: .curveEaseInOut
    ) {
      snapshotView.alpha = 1.0
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
  
  private func resetInteractionState() {
    interactionInProgress = false
    interruptedTranslation = 0
    enableOtherTouches()
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
    
    guard let transitionContext else { return }
    guard let options = transitioningOptions(for: transitionContext) else {
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    
    let fromView = options.fromView
    let fromFrame = options.fromRect
    let toView = options.toView
    let toFrame = options.toRect
    
    let presentedViewController = transitionContext.viewController(forKey: .from)
    let presentingViewController = transitionContext.viewController(forKey: .to)
    guard let config = configForPresentedViewController(presentedViewController)
      ?? configForPresentedViewController(presentingViewController) else {
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    
    guard let sourceView = config.sourceView else {
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    
    sourceViewWasHidden = sourceView.isHidden
    sourceView.isHidden = false
    
//    guard let snapshot = fromView.snapshotView(afterScreenUpdates: false) else {
//      transitionContext.completeTransition(false)
//      resetInteractionState()
//      return
//    }
    
    guard let snapshot = sourceView.resizableSnapshotView(from: sourceView.bounds,
                                                          afterScreenUpdates: false,
                                                          withCapInsets: .zero) else {
      sourceView.isHidden = sourceViewWasHidden
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    sourceView.isHidden = sourceViewWasHidden
    
    snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
    if let superviewBackgroundColor = snapshot.superview?.backgroundColor {
      snapshot.backgroundColor = sourceView.backgroundColor?.opaqueColor(over: superviewBackgroundColor)
    } else {
      snapshot.backgroundColor = sourceView.backgroundColor
    }
    snapshot.layer.cornerRadius = fromView.layer.cornerRadius
    
    let result = CGAffineTransform.transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    let maskFrame = toFrame.aspectFit(to: fromFrame)
    let initialCornerRadius: CGFloat = config.maskCornerRadius
    let finalCornerRadius: CGFloat = config.sourceView?.layer.cornerRadius ?? snapshot.layer.cornerRadius
    
    let mask = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .black
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = initialCornerRadius
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = config.dimmingColor
      $0.layer.opacity = 1.0
      $0.frame = toView.frame
    }
    
    let dimmingView: UIVisualEffectView? = config.dimmingVisualEffect.map {
      UIVisualEffectView(effect: $0).then {
        $0.frame = toView.frame
        $0.alpha = 1.0
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      }
    }
    let blurView: UIVisualEffectView? = config.maskVisualEffect.map {
      UIVisualEffectView(effect: $0).then {
        $0.alpha = 0.0
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.frame = fromView.bounds
      }
    }
    
    let shadowView = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .clear
      $0.layer.shadowColor = UIColor.black.cgColor
      $0.layer.shadowOpacity = 0.0
      $0.layer.shadowRadius = 20
      $0.layer.shadowOffset = .zero
      $0.layer.shouldRasterize = true
      $0.layer.rasterizationScale = UIScreen.main.scale
    }

    fromView.mask = mask
    transitionContext.containerView.insertSubview(shadowView, belowSubview: fromView)
    toView.addSubview(overlay)
    if let dimmingView {
      toView.addSubview(dimmingView)
    }
    snapshot.alpha = 0.0
    fromView.addSubview(snapshot)
    if let blurView {
      fromView.insertSubview(blurView, belowSubview: snapshot)
    }

    snapshot.frame = fromFrame

    self.fromView = fromView
    self.toView = toView
    self.config = config
    self.resultTransform = result.transform
    self.resultScaleFactor = result.scaleFactor
    self.initialMaskFrame = fromView.frame
    self.finalMaskFrame = maskFrame
    self.initialCornerRadius = initialCornerRadius
    self.finalCornerRadius = finalCornerRadius
    self.initialSnapshotCornerRadius = snapshot.layer.cornerRadius
    self.initialSnapshotFrame = fromFrame
    self.maskView = mask
    self.overlayView = overlay
    self.dimmingView = dimmingView
    self.blurView = blurView
    self.snapshotView = snapshot
    self.shadowView = shadowView

    config.sourceView?.isHidden = true
  }
  
  private func configForPresentedViewController(_ viewController: UIViewController?) -> ZoomOptions? {
    if let navigationController = viewController as? UINavigationController {
      return (navigationController.topViewController as? ZoomTransitioning)?.config
    }
    return (viewController as? ZoomTransitioning)?.config
  }
  
  private func interpolateValue(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
    from + (to - from) * progress
  }
  
  private func interpolateRect(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
    CGRect(
      x: interpolateValue(from: from.origin.x, to: to.origin.x, progress: progress),
      y: interpolateValue(from: from.origin.y, to: to.origin.y, progress: progress),
      width: interpolateValue(from: from.size.width, to: to.size.width, progress: progress),
      height: interpolateValue(from: from.size.height, to: to.size.height, progress: progress)
    )
  }
  
  private func interpolateTransform(from: CGAffineTransform, to: CGAffineTransform, progress: CGFloat) -> CGAffineTransform {
    CGAffineTransform(
      a: interpolateValue(from: from.a, to: to.a, progress: progress),
      b: interpolateValue(from: from.b, to: to.b, progress: progress),
      c: interpolateValue(from: from.c, to: to.c, progress: progress),
      d: interpolateValue(from: from.d, to: to.d, progress: progress),
      tx: interpolateValue(from: from.tx, to: to.tx, progress: progress),
      ty: interpolateValue(from: from.ty, to: to.ty, progress: progress)
    )
  }
  
  private func scaleFactor(for transform: CGAffineTransform) -> CGFloat {
    let scaleX = hypot(transform.a, transform.c)
    let scaleY = hypot(transform.b, transform.d)
    return max(scaleX, scaleY)
  }
  
  /// Clamps tx/ty so the view stays within the container during an interactive gesture.
  /// The view's transform is applied from its center, so after the transform:
  ///   centerX in container = containerCenterX + tx
  ///   centerY in container = containerCenterY + ty
  ///   scaledWidth  = viewBounds.width  * scale
  ///   scaledHeight = viewBounds.height * scale
  private func clampedTranslation(_ transform: CGAffineTransform, in containerBounds: CGRect, for viewBounds: CGRect) -> CGAffineTransform {
    let scale = hypot(transform.a, transform.c)
    let scaledWidth  = viewBounds.width  * scale
    let scaledHeight = viewBounds.height * scale

    // The view's center in container space after transform
    let containerCenterX = containerBounds.midX
    let containerCenterY = containerBounds.midY
    let centerX = containerCenterX + transform.tx
    let centerY = containerCenterY + transform.ty

    var tx = transform.tx
    var ty = transform.ty

    // midX must stay within [containerBounds.minX, containerBounds.maxX]
    if centerX < containerBounds.minX {
      tx += containerBounds.minX - centerX
    } else if centerX > containerBounds.maxX {
      tx -= centerX - containerBounds.maxX
    }

    // top edge must stay >= containerBounds.minY + 50
    let minY = centerY - scaledHeight / 2
    if minY < containerBounds.minY + 50 {
      ty += (containerBounds.minY + 50) - minY
    }

    // bottom edge must stay <= containerBounds.maxY - 50
    let maxY = centerY + scaledHeight / 2
    if maxY > containerBounds.maxY - 50 {
      ty -= maxY - (containerBounds.maxY - 50)
    }

    return CGAffineTransform(a: transform.a, b: transform.b, c: transform.c, d: transform.d, tx: tx, ty: ty)
  }
  
  private func clampedTransform(from: CGAffineTransform, to: CGAffineTransform, progress: CGFloat, minimumScale: CGFloat) -> CGAffineTransform {
    let transform = interpolateTransform(from: from, to: to, progress: progress)
    let scaleX = hypot(transform.a, transform.c)
    let scaleY = hypot(transform.b, transform.d)
    let minScale = max(minimumScale, 0.0)
    if scaleX >= minScale && scaleY >= minScale {
      return transform
    }
    let ratioX = scaleX == 0 ? minScale : minScale / scaleX
    let ratioY = scaleY == 0 ? minScale : minScale / scaleY
    let ratio = max(ratioX, ratioY, 1.0)
    return CGAffineTransform(
      a: transform.a * ratio,
      b: transform.b * ratio,
      c: transform.c * ratio,
      d: transform.d * ratio,
      tx: transform.tx * ratio,
      ty: transform.ty * ratio
    )
  }
  
  private func cleanUpTransitionViews() {
    fromView?.mask = nil
    overlayView?.removeFromSuperview()
    dimmingView?.removeFromSuperview()
    blurView?.removeFromSuperview()
    snapshotView?.removeFromSuperview()
    shadowView?.removeFromSuperview()
  }
}
