//
//  PHZoomInteractivePopInteractionController.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 25/12/25.
//

import UIKit
import ObjectiveC

public final class PHZoomInteractivePopInteractionController: NSObject, InteractiveTransitioning {
  private enum AssociatedKeys {
    // Each scroll view remembers which dismiss gestures it has already been wired to fail.
    // This matters for navigation-backed presentations: `setViewControllers(...)` can swap
    // the top controller without recreating this interaction controller, so we lazily wire
    // the newly exposed scroll view on first gesture evaluation instead of depending on init.
    static var wiredHorizontalDismissGesture: UInt8 = 0
    static var wiredVerticalDismissGesture: UInt8 = 0
  }

  private enum InteractionDriver {
    case pan
    case verticalPan
    case pinch
  }

  public var interactionInProgress = false
  /// Optional gate set by the `zoom()` caller. Takes precedence over the protocol property.
  public var interactiveDismissShouldBegin: (() -> Bool)?
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
  /// Reference to the rotation gesture recognizer so the pinch handler can read its cumulative
  /// `.rotation` value when computing the card's rotation. Two-finger twist is the natural way
  /// to detect rotation; the previous hand-rolled approach mapped horizontal pinch midpoint
  /// displacement to an angle, which conflated translation with rotation.
  private weak var rotationGestureRecognizer: UIRotationGestureRecognizer?
  /// Amplification factor on top of the user's actual finger twist. 1.0 = card matches finger
  /// rotation 1:1, higher values exaggerate.
  private let pinchRotationMultiplier: CGFloat = 1.0
  /// Smoothed rotation angle. Each `.changed` event eases toward the gesture's raw rotation
  /// (× multiplier) by at most `maxFrameDelta` radians, so finger jitter doesn't translate
  /// into visible micro-snaps on the card.
  private var smoothedRotationAngle: CGFloat = 0
  /// Rotation gesture's `.rotation` value captured at pinch `.began`. Subtracted from the
  /// current value so the card only sees rotation that happened *during* the pinch — without
  /// this, a user who twists before starting to pinch would see the card jump to the
  /// pre-pinch angle when pinch begins.
  private var rotationBaselineAtPinchBegin: CGFloat = 0
  /// Y position (in container coords) where the pan gesture began. Used as the scale pivot so
  /// the card visually anchors at the touch point instead of the geometric center.
  private var panAnchorY: CGFloat = 0
  /// X position (in container coords) where the *vertical* dismissal pan began. The vertical
  /// path scales the card toward the touch X so a drag-down doesn't visually drift sideways
  /// as the card shrinks.
  private var verticalPanAnchorX: CGFloat = 0
  /// Y position (in container coords) where the *vertical* dismissal pan began. Kept separate
  /// from `panAnchorY` (owned by the horizontal path) so the two flows never share state.
  private var verticalPanAnchorY: CGFloat = 0
  /// Container height captured when the vertical pan begins. Used as the denominator for
  /// progress and for the rubber-band shape, so vertical motion is sized against the screen
  /// it can travel through (height) instead of the horizontal-pan distance (width).
  private var verticalInteractionDistance: CGFloat = 0
  /// Visible-effect amplifier for the vertical pan: the card moves and shrinks this many
  /// times more than the raw rubber-band would produce, so the dismissal reads as more
  /// responsive without the user having to drag further. Read by `verticalUpdate` (applied
  /// to translation and scale) AND by `verticalGestureEnded` (scaled into the commit
  /// threshold so the finish-vs-cancel decision matches what the user sees on screen).
  private let verticalAmplification: CGFloat = 1.1
  /// Horizontal dismissal pan attached to the container view. Kept as a reference so any
  /// current `dismissibleScrollView` can require its own pan to fail this one, even after
  /// `setViewControllers(...)` swaps the visible child controller.
  private weak var dismissPanGesture: UIPanGestureRecognizer?
  /// Dedicated vertical-down dismissal pan attached to the main view. Distinct from the
  /// horizontal pan recognizer so the existing horizontal logic stays bit-identical.
  private weak var verticalDismissPanGesture: UIPanGestureRecognizer?
  /// EMA-smoothed pinch midpoint. Raw `gestureRecognizer.location(in:)` jitters because the
  /// centroid wobbles with sub-pixel finger movement; smoothing it strips the high-frequency
  /// noise so the card's translation reads as fluid finger-following instead of jittery snap.
  private var smoothedPinchLocation: CGPoint?
  
  // MARK: - Init
  
  public init(viewController: InteractiveDismissible & ZoomTransitioning) {
    self.viewController = viewController
    super.init()
    
    if let navigationController = viewController as? UINavigationController {
      prepareGestureRecognizer(in: navigationController.view)
    } else {
      prepareGestureRecognizer(in: viewController.view)
    }
    
  }
  
  private func prepareGestureRecognizer(in view: UIView) {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
    gesture.delegate = self
    view.addGestureRecognizer(gesture)
    dismissPanGesture = gesture

    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    pinchGesture.delegate = self
    view.addGestureRecognizer(pinchGesture)

    let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
    rotationGesture.delegate = self
    view.addGestureRecognizer(rotationGesture)
    rotationGestureRecognizer = rotationGesture

    // Vertical-down dismissal pan. Lives alongside the horizontal recognizer; the gates in
    // `gestureRecognizerShouldBegin(_:)` keep the two mutually exclusive (horizontal commits
    // on rightward+horizontal velocity, vertical on downward+vertical), so only one will ever
    // begin from any given touch.
    let verticalGesture = UIPanGestureRecognizer(target: self, action: #selector(handleVerticalGesture(_:)))
    verticalGesture.delegate = self
    view.addGestureRecognizer(verticalGesture)
    verticalDismissPanGesture = verticalGesture

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
    // Keep the actual dismissal recognizers on the container view. The scroll view only
    // participates by making its own pan wait for those recognizers to fail. This matches the
    // navigation-hosted interactive-pop fix and avoids attaching throwaway custom pans to each
    // new top controller's scroll view when `setViewControllers(...)` replaces the stack.
    if let dismissPanGesture,
       objc_getAssociatedObject(scrollView, &AssociatedKeys.wiredHorizontalDismissGesture) as? UIPanGestureRecognizer !== dismissPanGesture {
      scrollView.panGestureRecognizer.require(toFail: dismissPanGesture)
      objc_setAssociatedObject(scrollView,
                               &AssociatedKeys.wiredHorizontalDismissGesture,
                               dismissPanGesture,
                               .OBJC_ASSOCIATION_ASSIGN)
    }

    if let verticalDismissPanGesture,
       objc_getAssociatedObject(scrollView, &AssociatedKeys.wiredVerticalDismissGesture) as? UIPanGestureRecognizer !== verticalDismissPanGesture {
      scrollView.panGestureRecognizer.require(toFail: verticalDismissPanGesture)
      objc_setAssociatedObject(scrollView,
                               &AssociatedKeys.wiredVerticalDismissGesture,
                               verticalDismissPanGesture,
                               .OBJC_ASSOCIATION_ASSIGN)
    }
  }

  internal func isHorizontalDismissGestureWired(to scrollView: UIScrollView) -> Bool {
    objc_getAssociatedObject(scrollView, &AssociatedKeys.wiredHorizontalDismissGesture) as? UIPanGestureRecognizer === dismissPanGesture
  }

  internal func isVerticalDismissGestureWired(to scrollView: UIScrollView) -> Bool {
    objc_getAssociatedObject(scrollView, &AssociatedKeys.wiredVerticalDismissGesture) as? UIPanGestureRecognizer === verticalDismissPanGesture
  }
  
  // MARK: - Gesture handling
  
  @objc
  private func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    // Use the superview of the animated view as the reference — it is never transformed,
    // so translation(in:) always returns stable screen-space values regardless of whether
    // the gesture is attached to the main view or the dismissibleScrollView.
    let vcView = (viewController as? UINavigationController)?.view ?? viewController?.view
    guard let referenceView = vcView?.superview ?? gestureRecognizer.view?.superview else {
      return
    }

    let translation = gestureRecognizer.translation(in: referenceView).x
    let translationY = gestureRecognizer.translation(in: referenceView).y
    let velocity = gestureRecognizer.velocity(in: referenceView).x

    switch gestureRecognizer.state {
    case .began:
      panAnchorY = gestureRecognizer.location(in: referenceView).y
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

  // MARK: - Vertical pan handling

  /// Dedicated handler for the vertical-down dismissal pan. Lives separately from
  /// `handleGesture(_:)` so the existing horizontal flow stays untouched. Drives progress
  /// off Y translation against `verticalInteractionDistance`, springs to `.identity` (cancel)
  /// or to `resultTransform` (finish) via the same `cancel`/`finish` paths the other drivers
  /// use — those are axis-agnostic.
  @objc
  private func handleVerticalGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    let vcView = (viewController as? UINavigationController)?.view ?? viewController?.view
    guard let referenceView = vcView?.superview ?? gestureRecognizer.view?.superview else {
      return
    }

    let translationX = gestureRecognizer.translation(in: referenceView).x
    let translationY = gestureRecognizer.translation(in: referenceView).y
    let velocityY = gestureRecognizer.velocity(in: referenceView).y

    switch gestureRecognizer.state {
    case .began:
      let location = gestureRecognizer.location(in: referenceView)
      verticalPanAnchorX = location.x
      verticalPanAnchorY = location.y
      // Capture the travel-space size now (referenceView is the container the animated view
      // sits in) so `verticalUpdate` and `verticalGestureEnded` have a denominator without
      // having to wait for `startInteractiveTransition`'s containerView read.
      verticalInteractionDistance = referenceView.bounds.height
      gestureBegan(driver: .verticalPan)

    case .changed:
      verticalGestureChanged(translationY: translationY, translationX: translationX)

    case .cancelled:
      verticalGestureCancelled(translationY: translationY, velocityY: velocityY)

    case .ended:
      verticalGestureEnded(translationY: translationY, velocityY: velocityY)

    default:
      break
    }
  }

  private func verticalGestureChanged(translationY: CGFloat, translationX: CGFloat) {
    // Reject upward travel — vertical dismissal is down-only. Without this guard, an upward
    // wander after a downward start would compute negative progress and rubber-band the card
    // into a "pre-dismissal" pose `verticalUpdate` isn't designed to resolve.
    if translationY < 0 {
      return
    }
    let distance = max(verticalInteractionDistance, 1)
    let progress = max(0.0, min(1.0, translationY / distance))
    verticalUpdate(progress: progress, translationY: translationY, translationX: translationX)
  }

  private func verticalGestureCancelled(translationY: CGFloat, velocityY: CGFloat) {
    if transitionContext == nil {
      resetInteractionState()
      return
    }
    cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translationY, gestureVelocity: velocityY))
  }

  private func verticalGestureEnded(translationY: CGFloat, velocityY: CGFloat) {
    if transitionContext == nil {
      resetInteractionState()
      return
    }

    // Same commit thresholds as horizontal — fast flick or past the midpoint without an
    // upward fling. Velocity is Y in points/sec (positive = downward). The translation gets
    // multiplied by `verticalAmplification` so the threshold tracks what the user *sees*
    // rather than the raw finger distance: `verticalUpdate` already inflates visible motion
    // by the same factor, so a finger drag that visually crosses the halfway point should
    // commit even though the raw `translationY` is still ~9% below `interactionDistance/2`.
    let amplifiedTranslationY = translationY * verticalAmplification
    let shouldFinish = velocityY > 300 || (amplifiedTranslationY > 150*verticalAmplification && velocityY > -300)
    let currentTranslationY = fromView?.transform.ty ?? 0.0
    let distanceToTravel = shouldFinish ? (resultTransform.ty - currentTranslationY) : -currentTranslationY
    let initialVelocity = springVelocity(distanceToTravel: distanceToTravel, gestureVelocity: velocityY)

    if shouldFinish {
      finish(initialSpringVelocity: initialVelocity)
    } else {
      cancel(initialSpringVelocity: initialVelocity)
    }
  }

  /// Per-frame transform composition for the vertical dismissal pan. Mirrors `update(...)`
  /// in shape but with Y as the primary axis: Y drives `scaleProgress`, the heavy 1:1
  /// rubber-band lives on Y, and the scale pivot anchors at `verticalPanAnchorX` so a
  /// drag-down doesn't drift the card sideways as it shrinks.
  private func verticalUpdate(progress: CGFloat, translationY: CGFloat, translationX: CGFloat) {
    guard let transitionContext,
          let fromView,
          let maskView,
          let overlayView,
          let snapshotView else {
      return
    }

    transitionContext.updateInteractiveTransition(progress)

    let minimumScale = zoomOption?.minimumScale ?? 0.5
    // Use a vertical-distance-sized rubber-band so the asymptote matches the screen height
    // the gesture travels through. The horizontal `weightedTranslation` is sized against
    // `interactionDistance` (width), which would compress the curve incorrectly here.
    // `verticalAmplification` (a stored constant) inflates the visible motion uniformly
    // across translation and scale; the same constant is applied to the commit threshold
    // in `verticalGestureEnded` so the finish/cancel decision matches what's drawn.
    let weightedTranslationY = weightedVerticalDismissalTranslation(translationY) * verticalAmplification
    let weightedTranslationX = weightedVerticalTranslation(translationX) * verticalAmplification
    let maxVisibleTranslation = weightedVerticalDismissalTranslation(verticalInteractionDistance)
    let rawScaleProgress = weightedTranslationY / max(maxVisibleTranslation, 1)
    let scaleProgress = max(0.0, min(1.0, rawScaleProgress * verticalAmplification))
    let weightedProgress = weightedScaleProgress(scaleProgress)

    var transform = interactiveTransform(progress: weightedProgress,
                                         translationX: weightedTranslationX,
                                         translationY: weightedTranslationY,
                                         minimumScale: minimumScale)
    // Use a *relaxed* clamp here. The horizontal `clampedTranslation` enforces a 50pt inset
    // on every edge — at scale ≈ 1 (start of any pan) the unscaled view IS the container
    // size, so those insets over-constrain by 100pt and the math resolves to ty ≈ -50,
    // making the card jump upward before catching up to the finger. The relaxed version
    // below keeps the X clamp tight (so the pivot adjustment can't push the card fully
    // off-screen sideways) but adds a `verticalOverflow` of off-screen overhang on the Y
    // axis so the card follows the finger 1:1 (modulo rubber-band) until the user has
    // travelled past `verticalOverflow`. By then scale has shrunk enough for the strict
    // bound to relax naturally.
    let verticalOverflow: CGFloat = 120
    transform = relaxedVerticalClampedTranslation(transform,
                                                  in: transitionContext.containerView.bounds,
                                                  for: fromView.bounds,
                                                  verticalOverflow: verticalOverflow)

    // Anchor the scale pivot at the gesture's start X so the card scales toward the touch
    // column instead of the geometric center — keeps the original-screen point at
    // `verticalPanAnchorX` pinned under the finger as the card shrinks.
    let currentScale = hypot(transform.a, transform.c)
    let pivotOffsetX = verticalPanAnchorX - fromView.bounds.midX
    transform.tx += pivotOffsetX * (1.0 - currentScale)

    fromView.transform = transform

    if let shadowView {
      let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
      shadowView.transform = transform
      shadowView.layer.shadowOpacity = Float(progress * 0.85)
      shadowView.layer.shadowPath = UIBezierPath(
        roundedRect: fromView.bounds,
        cornerRadius: cornerRadius
      ).cgPath
    }

    let cornerRadius = max(initialCornerRadius, interpolateValue(from: initialCornerRadius, to: finalCornerRadius, progress: progress))
    maskView.frame = initialMaskFrame
    maskView.layer.cornerRadius = cornerRadius
    overlayView.layer.opacity = Float(1.0 - progress)
    dimmingView?.alpha = dimmingView == nil ? (1.0 - progress) : 1.0
    blurView?.alpha = 0.0
    snapshotView.frame = initialSnapshotFrame
    snapshotView.layer.cornerRadius = cornerRadius
    snapshotView.alpha = 0.0

    if let presentedViewController = transitionContext.viewController(forKey: .from),
       let modalPresentationController = presentedViewController.presentationController as? PHZoomPresentationController {
      modalPresentationController.fadeView.alpha = 0.5 * (1.0 - progress)
    }
  }

  /// Gate for the vertical recognizer. Lives outside `gestureRecognizerShouldBegin(_:)` so
  /// the horizontal branch above doesn't grow conditionals — the horizontal gate just routes
  /// vertical recognizers here.
  private func shouldBeginVerticalPan(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
    guard zoomOptionForPresentedViewController(viewController)?.allowsVerticalPanDismissal ?? false else {
      return false
    }
    // If the dismissibleScrollView has a refresh control, the downward-pull-at-top gesture
    // belongs to it — competing with pull-to-refresh would either swallow the refresh
    // (user pulls down, card dismisses instead of refreshing) or fight it (refresh and
    // dismiss both partially activate). Surrender the vertical axis entirely; horizontal
    // pan dismissal is unaffected.
    if let scrollView = viewController.dismissibleScrollView, scrollView.refreshControl != nil {
      return false
    }
    let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
    let isDownwardPan = velocity.y > 0
    let isPrimarilyVertical = abs(velocity.y) > abs(velocity.x)
    guard isDownwardPan, isPrimarilyVertical else {
      return false
    }

    if let scrollView = viewController.dismissibleScrollView,
       let hostView = gestureRecognizer.view {
      // Only apply the "scroll must be at top" rule when the touch actually begins inside the
      // dismissible scroll view. For nav-hosted presentations the recognizer lives on the
      // container view, so without this hit-test any downward drag anywhere on screen would be
      // incorrectly blocked by the scroll view's current content offset.
      let location = gestureRecognizer.location(in: hostView)
      let locationInScrollView = hostView.convert(location, to: scrollView)
      if scrollView.bounds.contains(locationInScrollView) {
        return scrollView.contentOffset.y <= 0
      }
    }

    return true
  }

  @objc
  private func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
    let vcView = (viewController as? UINavigationController)?.view ?? viewController?.view
    guard let referenceView = vcView?.superview ?? gestureRecognizer.view?.superview else {
      return
    }

    let location = gestureRecognizer.location(in: referenceView)
    let progress = max(0.0, min(1.0, (1.0 - gestureRecognizer.scale) / 0.62))
    let pinchScale = resistedPinchScale(for: gestureRecognizer.scale)

    switch gestureRecognizer.state {
    case .began:
      guard gestureRecognizer.velocity < 0 else { return }
      guard gestureRecognizer.numberOfTouches >= 2 else { return }
      initialPinchLocation = location
      smoothedPinchLocation = location
      smoothedRotationAngle = 0
      rotationBaselineAtPinchBegin = rotationGestureRecognizer?.rotation ?? 0
      gestureBegan(driver: .pinch)

    case .changed:
      guard interactionDriver == .pinch else { return }
      // If a finger lifts mid-pinch we commit or cancel right away based on current state.
      // UIKit will eventually fire `.ended` when touches drop below two, but reacting here
      // keeps the dismissal responsive instead of waiting an extra event.
      if gestureRecognizer.numberOfTouches < 2 {
        interactionDriver = nil
        initialPinchLocation = nil
        smoothedPinchLocation = nil
        pinchEnded(progress: progress, velocity: gestureRecognizer.velocity)
        return
      }

      // EMA-smooth the centroid: blend the new sample 40% over the previous smoothed value.
      // Lower alpha = more smoothing (more lag); 0.4 is a sweet spot that removes the visible
      // wobble without making the card feel sluggish behind the fingers.
      let smoothingAlpha: CGFloat = 0.4
      let prevSmoothed = smoothedPinchLocation
      let smoothed: CGPoint
      if let prev = prevSmoothed {
        smoothed = CGPoint(x: prev.x * (1 - smoothingAlpha) + location.x * smoothingAlpha,
                           y: prev.y * (1 - smoothingAlpha) + location.y * smoothingAlpha)
      } else {
        smoothed = location
      }
      smoothedPinchLocation = smoothed

      // Rotation comes directly from the dedicated UIRotationGestureRecognizer — it reads the
      // actual two-finger twist in radians. Multiplied by `pinchRotationMultiplier` to amplify
      // the visible tilt vs. the real finger rotation, then clamped to a sane max.
      // Smooth rotation: ease toward the gesture's current rotation by at most ~3° per frame.
      // Removes finger jitter and any transient jumps without adding visible lag for slow twists.
      // Subtract the pre-pinch baseline so we only see rotation that accumulated *during* this
      // pinch — otherwise a twist before pinching would show as a sudden card rotation at start.
      let rawRotation = (rotationGestureRecognizer?.rotation ?? 0) - rotationBaselineAtPinchBegin
      let target = rawRotation * pinchRotationMultiplier
      let maxFrameDelta: CGFloat = .pi / 60
      let delta = target - smoothedRotationAngle
      let clampedDelta = max(-maxFrameDelta, min(maxFrameDelta, delta))
      smoothedRotationAngle += clampedDelta
      let rotationAngle = smoothedRotationAngle

      let driftX = smoothed.x - (initialPinchLocation?.x ?? smoothed.x)
      let driftY = smoothed.y - (initialPinchLocation?.y ?? smoothed.y)
      pinchChanged(progress: weightedPinchProgress(progress),
                   translationX: driftX,
                   translationY: driftY,
                   rotationAngle: rotationAngle,
                   pinchScale: pinchScale)

    case .cancelled:
      guard interactionDriver == .pinch else { return }
      initialPinchLocation = nil
      smoothedPinchLocation = nil
      pinchCancelled(scale: gestureRecognizer.scale, velocity: gestureRecognizer.velocity)

    case .ended:
      guard interactionDriver == .pinch else { return }
      initialPinchLocation = nil
      smoothedPinchLocation = nil
      pinchEnded(progress: progress, velocity: gestureRecognizer.velocity)

    default:
      break
    }
  }

  @objc
  private func handleRotationGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
    // The cumulative `.rotation` value is read inside the pinch `.changed` handler. This target
    // exists only so UIKit registers the gesture as active; the pinch handler fires often
    // enough during multi-touch to keep the card's rotation in sync.
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
    // Pass vertical drift through with rubber-band damping (see `weightedVerticalTranslation`).
    // The scale pivot still locks to `panAnchorY`, so the card scales from the touch point and
    // springs up/down on top of that — a free pull, not free drift, since the resistance grows
    // with travel.
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

  private func pinchChanged(progress: CGFloat, translationX: CGFloat, translationY: CGFloat, rotationAngle: CGFloat, pinchScale: CGFloat) {
    guard transitionContext != nil else {
      return
    }
    update(progress: progress,
           translation: translationX,
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
    // Pan drives scale from visible motion (post rubber-band) so the shrink stays 1:1 with
    // gesture distance. Pinch has no horizontal translation, so we use its own pre-eased
    // `progress` directly — otherwise the resultTransform interpolation would be zero and
    // the card would only shrink via `additionalScale` (which floors at ~0.62).
    let scaleProgress: CGFloat
    if interactionDriver == .pinch {
      scaleProgress = max(0.0, min(1.0, progress))
    } else {
      let maxVisibleTranslation = weightedTranslation(interactionDistance, progress: 1.0)
      scaleProgress = max(0.0, min(1.0, weightedTranslationX / max(maxVisibleTranslation, 1)))
    }
    let weightedProgress = weightedScaleProgress(scaleProgress)
    var transform = interactiveTransform(progress: weightedProgress,
                                         translationX: weightedTranslationX,
                                         translationY: weightedTranslationY,
                                         minimumScale: minimumScale)
    transform = clampedTranslation(transform, in: transitionContext.containerView.bounds, for: fromView.bounds)
    // Anchor the scale pivot at the gesture's start Y instead of the view's geometric center.
    // UIView transforms scale around the layer's center, so a pure scale leaves the card
    // visually shrinking around the screen middle. Adding `(pivotOffset)·(1-s)` to ty shifts
    // the view so the original-screen point at `panAnchorY` stays under the touch — the card
    // appears to scale outward from where the finger first landed, then slide right.
    if interactionDriver == .pan {
      let currentScale = hypot(transform.a, transform.c)
      let pivotOffsetY = panAnchorY - fromView.bounds.midY
      transform.ty += pivotOffsetY * (1.0 - currentScale)
    }
    transform = transform.scaledBy(x: additionalScale, y: additionalScale)
    transform = transform.rotated(by: rotationAngle)
    // Pinch tracking: override tx/ty so the card follows the pinch midpoint and the originally
    // touched card-point stays pinned under the fingers. Formula: tx/ty = drift + (P - C) − T·(P - C),
    // where drift is the pinch midpoint's movement, P is the initial pinch location, C is the
    // card center, and T is the matrix part of the current transform (handles scale + rotation
    // correctly). For pan we leave the existing pan-anchor logic alone.
    if interactionDriver == .pinch, let initialPinchLocation {
      let pivotOffsetX = initialPinchLocation.x - initialMaskFrame.midX
      let pivotOffsetY = initialPinchLocation.y - initialMaskFrame.midY
      let rotatedScaledPivotX = transform.a * pivotOffsetX + transform.c * pivotOffsetY
      let rotatedScaledPivotY = transform.b * pivotOffsetX + transform.d * pivotOffsetY
      transform.tx = translation + pivotOffsetX - rotatedScaledPivotX
      transform.ty = translationY + pivotOffsetY - rotatedScaledPivotY
    }
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
  
  // Exposed at `internal` (rather than `private`) so the regression test for the idempotency
  // guard can invoke it directly via `@testable import`. Not part of the public surface.
  internal func disableOtherTouches() {
    // Idempotent: if we already hold a snapshot of views we disabled, return early. Without this
    // guard, a re-entry (e.g. a new pan starting during a still-running cancel/finish animation)
    // would re-snapshot `subviews.filter(\.isUserInteractionEnabled)` — which is now empty
    // because the originals are still disabled — and clobber the references. The eventual
    // `enableOtherTouches()` would then restore nothing, leaving subviews stuck disabled and
    // taps dead while gestures (attached to `viewController.view` itself) keep working.
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
    interactionDriver = nil
    initialPinchLocation = nil
    enableOtherTouches()
  }
}

// MARK: - UIGestureRecognizerDelegate

extension PHZoomInteractivePopInteractionController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let scrollView = viewController.dismissibleScrollView {
      // Wire the current top controller's scroll view lazily so navigation-stack replacements
      // are handled even when the presented UINavigationController instance never changes.
      resolveScrollViewGestures(scrollView)
    }

    let shouldBeginGate = interactiveDismissShouldBegin ?? viewController.interactiveDismissShouldBegin
    if let shouldBegin = shouldBeginGate, !shouldBegin() {
      return false
    }

    if let navigationController = viewController as? UINavigationController,
       navigationController.viewControllers.count > 1 {
      return false
    }

    if let pinchGestureRecognizer = gestureRecognizer as? UIPinchGestureRecognizer {
      // Require at least two active touches before pinch can begin. UIPinchGestureRecognizer
      // defaults to two touches, but the explicit guard documents intent and protects against
      // any subclass/override that loosens the requirement.
      guard pinchGestureRecognizer.numberOfTouches >= 2 else { return false }
      return !interactionInProgress
    }

    if gestureRecognizer is UIRotationGestureRecognizer {
      // Always allow rotation to begin. It doesn't drive the dismissal on its own — the pinch
      // handler reads its `.rotation` value — but pinch sets `interactionInProgress = true`
      // before rotation can start, so gating on it here would block rotation entirely.
      return true
    }

    if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
      // Mirror pinch's gating: reject new pans while an interaction is in flight (most often
      // during the spring-back of a previous cancel/finish). Without this, a pan can re-enter
      // `gestureBegan` during the cancel animation, point the controller at a stale
      // transitionContext, and corrupt `disabledInteractionViews` bookkeeping.
      guard !interactionInProgress else { return false }
      // Vertical-only dismissal pan is gated separately below; this branch only services the
      // horizontal recognizer the existing logic owns.
      if panGestureRecognizer === verticalDismissPanGesture {
        return shouldBeginVerticalPan(panGestureRecognizer)
      }
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

  /// Allow the rotation gesture and pinch gesture to recognize together — they need to be
  /// concurrent so a two-finger twist + scale produces both effects at once. All other pairs
  /// keep UIKit's default mutual exclusion.
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    let isPinch = gestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UIPinchGestureRecognizer
    let isRotation = gestureRecognizer is UIRotationGestureRecognizer || otherGestureRecognizer is UIRotationGestureRecognizer
    return isPinch && isRotation
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

  /// Sibling of `clampedTranslation` for the vertical dismissal pan. X clamping is identical
  /// (keeps the card from drifting fully off-screen sideways once the pivot adjustment kicks
  /// in). Y clamping uses a NEGATIVE inset of `verticalOverflow` points — i.e., the view is
  /// allowed to extend `verticalOverflow` past each container edge before clamping kicks in.
  /// The strict ±50pt inset that horizontal pan uses would force ty ≈ -50 at scale 1 (start
  /// of the gesture), making the card jump upward; the relaxed bound lets the card track the
  /// finger 1:1 through the early gesture, then re-engages once travel exceeds the overflow.
  private func relaxedVerticalClampedTranslation(_ transform: CGAffineTransform,
                                                 in containerBounds: CGRect,
                                                 for viewBounds: CGRect,
                                                 verticalOverflow: CGFloat) -> CGAffineTransform {
    let scale = hypot(transform.a, transform.c)
    let scaledHeight = viewBounds.height * scale

    let containerCenterX = containerBounds.midX
    let containerCenterY = containerBounds.midY
    let centerX = containerCenterX + transform.tx
    let centerY = containerCenterY + transform.ty

    var tx = transform.tx
    var ty = transform.ty

    if centerX < containerBounds.minX {
      tx += containerBounds.minX - centerX
    } else if centerX > containerBounds.maxX {
      tx -= centerX - containerBounds.maxX
    }

    let allowedTop = containerBounds.minY - verticalOverflow
    let minY = centerY - scaledHeight / 2
    if minY < allowedTop {
      ty += allowedTop - minY
    }

    let allowedBottom = containerBounds.maxY + verticalOverflow
    let maxY = centerY + scaledHeight / 2
    if maxY > allowedBottom {
      ty -= maxY - allowedBottom
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
  
  /// Symmetric rubber-band for vertical drift on top of the pan anchor. Initial slope ~0.48
  /// (matches the previous linear damping for small drags), then asymptotes to
  /// `interactionDistance` so big pulls progressively load up like a spring instead of running
  /// linearly off-screen. Mirrored for negative translation so up and down feel identical.
  private func weightedVerticalTranslation(_ translation: CGFloat) -> CGFloat {
    guard interactionDistance > 0 else { return translation * 0.48 }
    let c: CGFloat = 0.48
    let d = interactionDistance
    let absT = abs(translation)
    let resisted = d * (1.0 - 1.0 / (c * absT / d + 1.0))
    return translation < 0 ? -resisted : resisted
  }

  /// Same shape as `weightedTranslation` but sized against `verticalInteractionDistance`
  /// (container height) instead of `interactionDistance` (container width). Used by the
  /// vertical dismissal pan so the rubber-band asymptote matches the actual travel space.
  private func weightedVerticalDismissalTranslation(_ translation: CGFloat) -> CGFloat {
    guard verticalInteractionDistance > 0 else { return translation * 0.55 }
    let c: CGFloat = 0.82
    let d = verticalInteractionDistance
    return d * (1.0 - 1.0 / (c * translation / d + 1.0))
  }
  
  /// Let scaling lag behind the raw gesture progress a bit to avoid a weightless feel.
  private func weightedScaleProgress(_ progress: CGFloat) -> CGFloat {
    let clampedProgress = max(0.0, min(1.0, progress))
    return pow(clampedProgress, 1.52)
  }

  private func weightedPinchProgress(_ progress: CGFloat) -> CGFloat {
    let clampedProgress = max(0.0, min(1.0, progress))
    return pow(clampedProgress, 2.08)
  }

  /// Rubber-band resistance for the pinch additional scale. Same shape as horizontal pan:
  /// initial slope `c` (responsive at small pinches) and asymptote at `1 - maxAmount` (no hard
  /// floor — pinching harder yields progressively less shrink, never snapping). With c=1.5 and
  /// maxAmount=0.85: scale 0.95 → ~0.93, 0.7 → ~0.71, 0.5 → ~0.60, 0.2 → ~0.50, ∞ → 0.15.
  private func resistedPinchScale(for scale: CGFloat) -> CGFloat {
    let pinchAmount = max(0.0, 1.0 - scale)
    let c: CGFloat = 1.5
    let maxAmount: CGFloat = 0.85
    let resisted = maxAmount * (1.0 - 1.0 / (c * pinchAmount / maxAmount + 1.0))
    return 1.0 - resisted
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
