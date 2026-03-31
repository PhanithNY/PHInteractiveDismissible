//
//  PHZoomInteractivePopInteractionController.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 25/12/25.
//

import UIKit

public final class PHZoomInteractivePopInteractionController: NSObject, InteractiveTransitioning {
  private enum InteractionDriver {
    case pan
    case pinch
  }
  
  public var interactionInProgress = false
  private weak var viewController: (InteractiveDismissible & ZoomTransitioning)!
  private weak var transitionContext: UIViewControllerContextTransitioning?
  
  private var interactionDistance: CGFloat = 0
  private var interruptedTranslation: CGFloat = 0
  
  private weak var fromView: UIView?
  private weak var toView: UIView?
  private var zoomOption: ZoomOptions?
  private var resultTransform: CGAffineTransform = .identity
  private var resultScaleFactor: CGFloat = 1.0
  private var initialMaskFrame: CGRect = .zero
  private var finalMaskFrame: CGRect = .zero
  private var initialCornerRadius: CGFloat = 0
  private var finalCornerRadius: CGFloat = 0
  private var initialSnapshotFrame: CGRect = .zero
  
  private weak var maskView: UIView?
  private weak var overlayView: UIView?
  private weak var dimmingView: UIVisualEffectView?
  private weak var blurView: UIVisualEffectView?
  private weak var snapshotView: UIView?
  private weak var shadowView: UIView?
  private weak var sourceView: UIView?
  private var sourceViewWasHidden: Bool = false
  private var disabledInteractionViews: [UIView] = []
  private var shadowFinalFrame: CGRect = .zero
  private var interactionDriver: InteractionDriver?
  private var initialPinchLocation: CGPoint?
  private var pinchRotationAngle: CGFloat = 0.0
  private let pinchRotationMultiplier: CGFloat = 1.35
  
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
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    gesture.delegate = self
    view.addGestureRecognizer(gesture)

    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    pinchGesture.delegate = self
    view.addGestureRecognizer(pinchGesture)
    
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
    let translationY = gestureRecognizer.translation(in: superview).y
    let velocity = gestureRecognizer.velocity(in: superview).x
    
    switch gestureRecognizer.state {
    case .began:
      gestureBegan(driver: .pan)
      
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
  
  @objc
  private func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
    guard let superview = gestureRecognizer.view?.superview else {
      return
    }

    let location = gestureRecognizer.location(in: superview)
    let progress = max(0.0, min(1.0, (1.0 - gestureRecognizer.scale) / 0.62))
    let translationY = weightedPinchVerticalTranslation((location.y - superview.bounds.midY) * progress * 0.18)
    let pinchScale = resistedPinchScale(for: gestureRecognizer.scale)

    switch gestureRecognizer.state {
    case .began:
      guard gestureRecognizer.velocity < 0 else { return }
      initialPinchLocation = location
      pinchRotationAngle = 0.0
      gestureBegan(driver: .pinch)

    case .changed:
      guard interactionDriver == .pinch else { return }
      let rotationAngle = updatePinchRotationAngle(location: location,
                                                   progress: progress,
                                                   containerWidth: superview.bounds.width)
      pinchChanged(progress: weightedPinchProgress(progress),
                   translationY: translationY,
                   rotationAngle: rotationAngle,
                   pinchScale: pinchScale)

    case .cancelled:
      guard interactionDriver == .pinch else { return }
      initialPinchLocation = nil
      pinchCancelled(scale: gestureRecognizer.scale, velocity: gestureRecognizer.velocity)

    case .ended:
      guard interactionDriver == .pinch else { return }
      initialPinchLocation = nil
      pinchEnded(progress: progress, velocity: gestureRecognizer.velocity)

    default:
      break
    }
  }
  
  private func gestureBegan(driver: InteractionDriver) {
    disableOtherTouches()
    
    interruptedTranslation = 0
    interactionDriver = driver
    
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
    update(progress: progress,
           translation: translation,
           translationY: translationY,
           rotationAngle: 0.0,
           additionalScale: 1.0)
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

    let shouldFinish = velocity > 300 || (translation > interactionDistance / 2.0 && velocity > -300)
    let currentTranslationX = fromView?.transform.tx ?? 0.0
    let distanceToTravel = shouldFinish ? (resultTransform.tx - currentTranslationX) : -currentTranslationX
    let initialVelocity = springVelocity(distanceToTravel: distanceToTravel, gestureVelocity: velocity)

    if shouldFinish {
      finish(initialSpringVelocity: initialVelocity)
    } else {
      cancel(initialSpringVelocity: initialVelocity)
    }
  }

  private func pinchChanged(progress: CGFloat, translationY: CGFloat, rotationAngle: CGFloat, pinchScale: CGFloat) {
    guard transitionContext != nil else {
      return
    }
    update(progress: progress,
           translation: 0.0,
           translationY: translationY,
           rotationAngle: rotationAngle,
           additionalScale: pinchScale)
  }

  private func pinchCancelled(scale: CGFloat, velocity: CGFloat) {
    guard transitionContext != nil else {
      resetInteractionState()
      return
    }
    let distanceToTravel = max(0.0, 1.0 - scale)
    cancel(initialSpringVelocity: springVelocity(distanceToTravel: -distanceToTravel, gestureVelocity: velocity * 180.0))
  }

  private func pinchEnded(progress: CGFloat, velocity: CGFloat) {
    guard transitionContext != nil else {
      resetInteractionState()
      return
    }

    let shouldFinish = velocity < -0.75 || (progress > 0.32 && velocity < 0.8)
    let currentTranslationX = fromView?.transform.tx ?? 0.0
    let distanceToTravel = shouldFinish ? (resultTransform.tx - currentTranslationX) : -currentTranslationX
    let initialVelocity = springVelocity(distanceToTravel: distanceToTravel, gestureVelocity: (-velocity) * 220.0)

    if shouldFinish {
      finish(initialSpringVelocity: initialVelocity)
    } else {
      cancel(initialSpringVelocity: initialVelocity)
    }
  }
  
  // MARK: - Transition controlling
  
  private func transitioningOptions(for context: UIViewControllerContextTransitioning) -> ZoomTransitioning.Options? {
    guard let fromView = context.viewController(forKey: .from)?.view,
          let toView = context.viewController(forKey: .to)?.view else {
      return nil
    }
    
    guard let toRect = context.zoomRect(forKey: .to, transition: .dismiss),
          let fromRect = context.zoomRect(forKey: .from, transition: .dismiss) else {
      return nil
    }
    
    return ZoomTransitioning.Options(fromView: fromView, fromRect: fromRect, toView: toView, toRect: toRect)
  }
  
  public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
    self.transitionContext = transitionContext
    interactionDistance = transitionContext.containerView.bounds.width
    
    prepareLayouts()
  }
  
  private func update(progress: CGFloat,
                      translation: CGFloat,
                      translationY: CGFloat,
                      rotationAngle: CGFloat,
                      additionalScale: CGFloat) {
    guard let transitionContext,
          let fromView,
          let maskView,
          let overlayView,
          let snapshotView else {
      return
    }

    transitionContext.updateInteractiveTransition(progress)

    let minimumScale = zoomOption?.minimumScale ?? 0.5
    let weightedTranslationX = weightedTranslation(translation, progress: progress)
    let weightedTranslationY = weightedVerticalTranslation(translationY)
    let weightedProgress = weightedScaleProgress(progress)
    var transform = interactiveTransform(progress: weightedProgress,
                                         translationX: weightedTranslationX,
                                         translationY: weightedTranslationY,
                                         minimumScale: minimumScale)
    transform = clampedTranslation(transform, in: transitionContext.containerView.bounds, for: fromView.bounds)
    transform = transform.scaledBy(x: additionalScale, y: additionalScale)
    transform = transform.rotated(by: rotationAngle)
    fromView.transform = transform

    if let shadowView {
//      let scale = hypot(transform.a, transform.c)
      let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
      shadowView.transform = transform
      shadowView.layer.shadowOpacity = Float(progress * 0.85)
      shadowView.layer.shadowPath = UIBezierPath(
        roundedRect: fromView.bounds,//CGRect(origin: .zero, size: fromView.bounds.size),
        cornerRadius: cornerRadius // scale
      ).cgPath
    }
    
    let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
    maskView.frame = initialMaskFrame
    maskView.layer.cornerRadius = cornerRadius
    overlayView.layer.opacity = Float(1.0 - progress)
    dimmingView?.alpha = dimmingView == nil ? (1.0 - progress) : 1.0 //1.0 - progress
    blurView?.alpha = 0.0//progress
    snapshotView.frame = initialSnapshotFrame
    snapshotView.layer.cornerRadius = cornerRadius
    snapshotView.alpha = 0.0
    
    // Removable
    if let presentedViewController = transitionContext.viewController(forKey: .from),
       let modalPresentationController = presentedViewController.presentationController as? PHZoomPresentationController {
      modalPresentationController.fadeView.alpha = 0.5 * (1.0 - progress)
    }
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
      springDuration: zoomOption?.duration ?? 0.35,
      bounce: 0.12,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: [.curveEaseInOut]) {
        fromView.transform = .identity
        maskView.frame = self.initialMaskFrame
        maskView.layer.cornerRadius = self.initialCornerRadius
        overlayView.layer.opacity = 1.0
        self.dimmingView?.alpha = 1.0
        self.dimmingView?.effect = self.zoomOption?.dimmingVisualEffect
        self.blurView?.alpha = 0.0
        snapshotView.frame = self.initialSnapshotFrame
        snapshotView.layer.cornerRadius = self.initialCornerRadius
        self.shadowView?.transform = .identity
        self.shadowView?.layer.shadowOpacity = 0.0
        self.shadowView?.layer.shadowPath = UIBezierPath(
          roundedRect: CGRect(origin: .zero, size: fromView.bounds.size),
          cornerRadius: self.initialCornerRadius
        ).cgPath
        if let modalPresentationController = transitionContext.viewController(forKey: .from)?.presentationController as? PHZoomPresentationController {
          modalPresentationController.fadeView.alpha = 0.5
        }
      } completion: { [weak self] _ in
        transitionContext.cancelInteractiveTransition()
        transitionContext.completeTransition(false)
        self?.sourceView?.isHidden = self?.sourceViewWasHidden ?? false
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
    let finishDuration = max((zoomOption?.duration ?? 0.35) * 1.32, 0.5)
    UIView.springAnimate(
      springDuration: finishDuration,
      bounce: 0.2,
      initialSpringVelocity: initialSpringVelocity * 0.8,
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
        self.shadowView?.layer.shadowPath = UIBezierPath(
          roundedRect: self.shadowFinalFrame,
          cornerRadius: self.finalCornerRadius / self.resultScaleFactor
        ).cgPath
        
        snapshotView.alpha = 1.0
        if let modalPresentationController = transitionContext.viewController(forKey: .from)?.presentationController as? PHZoomPresentationController {
          modalPresentationController.fadeView.alpha = 0.0
        }
      } completion: { [weak self] _ in
        transitionContext.finishInteractiveTransition()
        transitionContext.completeTransition(true)
        self?.sourceView?.isHidden = false
        self?.cleanUpTransitionViews()
        self?.resetInteractionState()
      }
  }
  
  // MARK: - Helpers
  
  /// Normalizes gesture velocity for UIKit spring APIs.
  /// Keep the value conservative so the spring settles with visible weight instead of snapping.
  private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
    let normalizedDistance = max(abs(distanceToTravel), 28.0)
    let normalizedVelocity = gestureVelocity / normalizedDistance
    return max(-8.0, min(8.0, normalizedVelocity))
  }
  
  private func disableOtherTouches() {
    disabledInteractionViews = viewController.view.subviews.filter(\.isUserInteractionEnabled)
    disabledInteractionViews.forEach {
      $0.isUserInteractionEnabled = false
    }
  }
  
  private func enableOtherTouches() {
    disabledInteractionViews.forEach {
      $0.isUserInteractionEnabled = true
    }
    disabledInteractionViews.removeAll()
  }
  
  private func resetInteractionState() {
    interactionInProgress = false
    interruptedTranslation = 0
    interactionDriver = nil
    initialPinchLocation = nil
    pinchRotationAngle = 0.0
    enableOtherTouches()
  }
}

// MARK: - UIGestureRecognizerDelegate

extension PHZoomInteractivePopInteractionController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let navigationController = viewController as? UINavigationController,
       navigationController.viewControllers.count > 1 {
      return false
    }

    if gestureRecognizer is UIPinchGestureRecognizer {
      return !interactionInProgress
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

extension PHZoomInteractivePopInteractionController {
  private func prepareLayouts() {
    guard let transitionContext else { return }
    transitionContext.synchronizeZoomTransitionLayout()
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
    guard let zoomOption = zoomOptionForPresentedViewController(presentedViewController)
      ?? zoomOptionForPresentedViewController(presentingViewController) else {
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    
    guard let sourceView = transitionContext.sourceView(forKey: .from, transition: .dismiss)
      ?? transitionContext.sourceView(forKey: .to, transition: .dismiss) else {
      transitionContext.completeTransition(false)
      resetInteractionState()
      return
    }
    
    let result = CGAffineTransform.transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    let maskFrame = toFrame.aspectFit(to: fromFrame)
    let initialCornerRadius: CGFloat = zoomOption.maskCornerRadius
    
    let mask = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .black
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = initialCornerRadius
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = zoomOption.dimmingColor
      $0.layer.opacity = 1.0
      $0.frame = toView.frame
    }
    
    let dimmingView: UIVisualEffectView? = zoomOption.dimmingVisualEffect.map {
      UIVisualEffectView(effect: $0).then {
        $0.frame = toView.frame
        $0.alpha = 1.0
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      }
    }
    let blurView: UIVisualEffectView? = zoomOption.maskVisualEffect.map {
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
      $0.layer.shadowRadius = 16
      $0.layer.shadowOffset = .zero
      $0.layer.shouldRasterize = true
      $0.layer.rasterizationScale = UIScreen.main.scale
      $0.layer.shadowPath = UIBezierPath(
        roundedRect: CGRect(origin: .zero, size: fromView.bounds.size),
        cornerRadius: initialCornerRadius
      ).cgPath
    }

    fromView.mask = mask
    transitionContext.containerView.insertSubview(shadowView, belowSubview: fromView)
    toView.addSubview(overlay)
    if let dimmingView {
      toView.addSubview(dimmingView)
    }
    
    sourceViewWasHidden = sourceView.isHidden
    sourceView.isHidden = false
    sourceView.layoutIfNeeded()

    guard let snapshot = sourceView.resizableSnapshotView(from: sourceView.bounds, afterScreenUpdates: true, withCapInsets: .zero) else {
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
    
    fromView.addSubview(snapshot)
    snapshot.frame = fromFrame
    snapshot.alpha = 0.0
    
    if let blurView {
      fromView.insertSubview(blurView, belowSubview: snapshot)
    }
    
    let finalCornerRadius: CGFloat = sourceView.layer.cornerRadius

    self.fromView = fromView
    self.toView = toView
    self.zoomOption = zoomOption
    self.resultTransform = result.transform
    self.resultScaleFactor = result.scaleFactor
    self.initialMaskFrame = fromView.frame
    self.finalMaskFrame = maskFrame
    self.initialCornerRadius = initialCornerRadius
    self.finalCornerRadius = finalCornerRadius
    self.initialSnapshotFrame = fromFrame
    self.maskView = mask
    self.overlayView = overlay
    self.dimmingView = dimmingView
    self.blurView = blurView
    self.snapshotView = snapshot
    self.shadowView = shadowView
    self.sourceView = sourceView
    self.shadowFinalFrame = maskFrame

    sourceView.isHidden = true
  }
  
  private func zoomOptionForPresentedViewController(_ viewController: UIViewController?) -> ZoomOptions? {
    viewController?.resolvedZoomTransitioning()?.zoomOption
  }
  
  private func interpolateValue(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
    from + (to - from) * progress
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

  /// Uses gesture translation for motion while keeping progress-driven scale interpolation.
  /// The final dismissal transform can translate left, center, or right depending on the
  /// source view location, but during interaction the content should follow the user's pan.
  private func interactiveTransform(progress: CGFloat,
                                    translationX: CGFloat,
                                    translationY: CGFloat,
                                    minimumScale: CGFloat) -> CGAffineTransform {
    let scaledTransform = clampedTransform(from: .identity,
                                           to: resultTransform,
                                           progress: progress,
                                           minimumScale: minimumScale)
    return CGAffineTransform(a: scaledTransform.a,
                             b: scaledTransform.b,
                             c: scaledTransform.c,
                             d: scaledTransform.d,
                             tx: translationX,
                             ty: translationY)
  }
  
  /// Rubber-band resistance: near 1:1 at the start, progressively heavier as the view is pulled further.
  /// The classic formula `d * (1 - 1 / (c*x/d + 1))` gives a natural spring-like stretch —
  /// the view loads up with tension the farther it travels, rather than sliding with a flat multiplier.
  private func weightedTranslation(_ translation: CGFloat, progress: CGFloat) -> CGFloat {
    guard interactionDistance > 0 else { return translation * 0.55 }
    let c: CGFloat = 0.82   // tension coefficient — lower = stiffer spring
    let d = interactionDistance
    return d * (1.0 - 1.0 / (c * translation / d + 1.0))
  }
  
  /// Vertical motion should feel slightly damped so the card keeps some mass.
  private func weightedVerticalTranslation(_ translation: CGFloat) -> CGFloat {
    translation * 0.48
  }
  
  /// Let scaling lag behind the raw gesture progress a bit to avoid a weightless feel.
  private func weightedScaleProgress(_ progress: CGFloat) -> CGFloat {
    let clampedProgress = max(0.0, min(1.0, progress))
    return pow(clampedProgress, 1.52)
  }

  private func weightedPinchRotationProgress(_ progress: CGFloat) -> CGFloat {
    let clampedProgress = max(0.0, min(1.0, progress))
    return pow(clampedProgress, 1.18)
  }

  private func weightedPinchProgress(_ progress: CGFloat) -> CGFloat {
    let clampedProgress = max(0.0, min(1.0, progress))
    return pow(clampedProgress, 2.08)
  }

  private func weightedPinchVerticalTranslation(_ translation: CGFloat) -> CGFloat {
    translation * 0.24
  }

  private func updatePinchRotationAngle(location: CGPoint, progress: CGFloat, containerWidth: CGFloat) -> CGFloat {
    guard let initialPinchLocation else {
      return pinchRotationAngle
    }

    let deltaX = location.x - initialPinchLocation.x
    let normalizedDeltaX = deltaX / max(containerWidth / 2.0, 1.0)
    let rotationProgress = max(0.22, weightedPinchRotationProgress(progress))
    let incrementalRotation = -normalizedDeltaX * (.pi / 5.5) * rotationProgress * pinchRotationMultiplier
    let maxRotation = (.pi / 6.8)
    pinchRotationAngle = max(-maxRotation, min(maxRotation, incrementalRotation))
    return pinchRotationAngle
  }

  private func resistedPinchScale(for scale: CGFloat) -> CGFloat {
    let clampedScale = max(0.62, min(1.0, scale))
    let normalized = (1.0 - clampedScale) / 0.38
    let resistedProgress = pow(max(0.0, min(1.0, normalized)), 2.35)
    return 1.0 - (resistedProgress * 0.38)
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
