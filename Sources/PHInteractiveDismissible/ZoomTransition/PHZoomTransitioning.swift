//
//  PHZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import Foundation
import SwiftUI
import UIKit

public class PHZoomTransitioning: NSObject {
  
  // MARK: Inner types
  
  public enum Transition {
    case present
    case dismiss
  }
  
  // MARK: Public properties
  
  public var transition: Transition = .present
  
  private var sourceView: UIView?
  
  private var config: ZoomOptions = .default
  
}

// MARK: - UIViewControllerAnimatedTransitioning

extension PHZoomTransitioning: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    config.duration
  }
  
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    prepareViewControllers(from: transitionContext, for: transition)
    
    switch transition {
    case .present:
      animationForPresentation(from: transitionContext)
      
    case .dismiss:
      animationForDismissal(from: transitionContext)
    }
  }
}

// MARK: - Animations

extension PHZoomTransitioning {
  private func animationForPresentation(from context: UIViewControllerContextTransitioning) {
    
    // Create and cache snapshot of the source view
    guard let sourceView = context.sourceView(forKey: .from, transition: transition)
      ?? context.sourceView(forKey: .to, transition: transition) else {
      context.completeTransition(false)
      return
    }
    
    guard let snapshot = makeSnapshot(from: sourceView) else {
      context.completeTransition(false)
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
    self.sourceView = snapshot
    
    guard let options = transitioningOptions(for: context) else {
      context.completeTransition(false)
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
    
    // Our mask view
    let mask = UIView(frame: maskFrame).then {
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
    
    // Duration to morph from snapshot and blur view to destination view.
    let morphDuration = config.duration * 0.25
    
    // Delay duration for blur effect from effect to nil
    let delayMorphDuration: TimeInterval = config.duration * 0.15
    
    // The animation duration
    let springDuration: TimeInterval = config.duration * 0.75
    
    // Hide sourceView
    sourceView.isHidden = true
    
    // Fade out snapshot
    UIView.springAnimate(
      springDuration: config.maskVisualEffect == nil ? config.duration * 0.1 : morphDuration,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: 0.0,
      options: .curveEaseInOut
    ) {
      snapshot.alpha = 0.0
      blurView.contentView.backgroundColor = toView.backgroundColor
    }
    
    // Remove blur
    UIView.springAnimate(
      springDuration: morphDuration,
      bounce: 0.0,
      initialSpringVelocity: 0.0,
      delay: delayMorphDuration,
      options: .curveEaseInOut
    ) {
      blurView.effect = nil
    }
    
    // Main zoom animation with subtle bounce
    UIView.springAnimate(
      springDuration: springDuration,
      bounce: 0.075,
      initialSpringVelocity: 0.0,
      delay: 0.0,
      options: .curveEaseInOut
    ) { [self] in
      toView.transform = .identity
      mask.frame = toView.frame
      mask.layer.cornerRadius = finalCornerRadius
      overlay.layer.opacity = 1.0
      dimmingView.effect = config.dimmingVisualEffect
      snapshot.frame = toView.frame
    } completion: { [self] _ in
      sourceView.isHidden = true
      blurView.removeFromSuperview()
      snapshot.removeFromSuperview()
      toView.mask = nil
      overlay.removeFromSuperview()
      dimmingView.removeFromSuperview()
      context.completeTransition(true)
    }
  }
  
  private func animationForDismissal(from context: UIViewControllerContextTransitioning) {
    guard let options = transitioningOptions(for: context) else {
      context.completeTransition(false)
      return
    }
    
    let fromView = options.fromView
    let fromFrame = options.fromRect
    let toView = options.toView
    let toFrame = options.toRect
    
    let baseSnapshot: UIView
    let resolvedSourceView = context.sourceView(forKey: .from, transition: transition)
      ?? context.sourceView(forKey: .to, transition: transition)
    
    if let sourceView {
      baseSnapshot = sourceView
    } else if let resolvedSourceView,
              let snapshot = makeSnapshot(from: resolvedSourceView) {
      baseSnapshot = snapshot
      self.sourceView = snapshot
    } else {
      context.completeTransition(false)
      return
    }
    
    let snapshot = baseSnapshot.then {
      $0.alpha = 0.0
      $0.frame = fromFrame
    }
    
    let result = CGAffineTransform.transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    // Our mask view
    let mask = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .black
      $0.layer.cornerRadius = config.maskCornerRadius
      $0.layer.masksToBounds = true
    }
    
    // Our overlay view
    let overlay = UIView().then {
      $0.backgroundColor = config.dimmingColor
      $0.layer.opacity = 1.0
      $0.frame = toView.frame
    }
    
    // Our dimmingEffect view
    let dimmingView = makeDimmingVisualEffectView().then {
      $0.frame = toView.frame
    }
    
    fromView.mask = mask
    
    // Position overlay on top of destination view, in this case toView
    toView.addSubview(overlay)
    
    // Position blur effect on top of overlay
    toView.addSubview(dimmingView)
    
    // Position snapshot
    fromView.addSubview(snapshot)
    
    let maskFrame = toFrame.aspectFit(to: fromFrame)
    
    // Create blur effect for morphing
    let blurEffect = config.maskVisualEffect
    let blurView = UIVisualEffectView(effect: nil).then {
      $0.alpha = 0.0
      $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      $0.frame = fromView.bounds
    }
    fromView.insertSubview(blurView, belowSubview: snapshot)
    
    // The duration for morph between zero blur to fully blur with snapshot visible
    let morphDuration = config.duration * 0.25
    
    // Calculate morph timing
    let morphDelay = config.maskVisualEffect == nil ? (config.duration * 0.3) : config.duration * 0.5
    
    UIView.springAnimate(
      springDuration: config.duration,
      bounce: 0.1,
      initialSpringVelocity: 0.0,
      delay: 0.0,
      options: [.curveEaseInOut, .allowUserInteraction]
    ) {
      fromView.transform = result.transform
      mask.frame = maskFrame
      mask.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
      overlay.layer.opacity = 0
      dimmingView.effect = nil
      snapshot.frame = maskFrame
      snapshot.layer.cornerRadius = 0
      blurView.contentView.backgroundColor = snapshot.backgroundColor
      blurView.alpha = 1.0
      
    } completion: { _ in
      resolvedSourceView?.isHidden = false
      fromView.mask = nil
      blurView.removeFromSuperview()
      snapshot.removeFromSuperview()
      overlay.removeFromSuperview()
      dimmingView.removeFromSuperview()
      let isCancelled = context.transitionWasCancelled
      context.completeTransition(!isCancelled)
    }
    
    // Animate blur visibility
    UIView.springAnimate(
      springDuration: morphDuration,
      bounce: 0.0,
      initialSpringVelocity: 0.0,
      delay: config.duration * 0.15,
      options: .curveEaseInOut
    ) {
      blurView.effect = blurEffect
    }
    
    // Crossfade to snapshot during blur
    UIView.springAnimate(
      springDuration: morphDuration,
      bounce: 0.0,
      initialSpringVelocity: 10.0,
      delay: morphDelay,
      options: .curveEaseInOut
    ) {
      snapshot.alpha = 1.0
    }
  }
}

// MARK: Helpers

extension PHZoomTransitioning {
  private func makeSnapshot(from sourceView: UIView) -> UIView? {
    let sourceViewWasHidden = sourceView.isHidden
    sourceView.isHidden = false
    sourceView.layoutIfNeeded()
    let snapshot = sourceView.snapshotView(afterScreenUpdates: true)
    sourceView.isHidden = sourceViewWasHidden
    return snapshot
  }
  
  private func makeDimmingVisualEffectView() -> UIVisualEffectView {
    let effect = config.dimmingVisualEffect
    let view = UIVisualEffectView(effect: effect)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return view
  }
  
  private func prepareViewControllers(from context: UIViewControllerContextTransitioning,
                                      for transition: Transition) {
    let fromVC = context.viewController(forKey: .from)?.resolvedZoomTransitioning()
    let toVC = context.viewController(forKey: .to)?.resolvedZoomTransitioning()

    switch transition {
    case .present:
      config = toVC?.config ?? fromVC?.config ?? .default
    case .dismiss:
      config = fromVC?.config ?? toVC?.config ?? .default
    }

    fromVC?.prepare(for: transition)
    toVC?.prepare(for: transition)
  }
  
  private func transitioningOptions(for context: UIViewControllerContextTransitioning) -> ZoomTransitioning.Options? {
    guard let fromView = context.viewController(forKey: .from)?.view,
          let toView = context.viewController(forKey: .to)?.view else {
      return nil
    }
    
    guard let toRect = context.sharedFrame(forKey: .to),
          let fromRect = context.sharedFrame(forKey: .from) else {
      return nil
    }
    
    if transition == .present {
      context.containerView.addSubview(toView)
    }
    
    return ZoomTransitioning.Options(fromView: fromView, fromRect: fromRect, toView: toView, toRect: toRect)
  }
}

extension UIView {
  
  public class func springAnimate(springDuration duration: TimeInterval = 0.5,
                                  bounce: CGFloat = 0.0,
                                  initialSpringVelocity: CGFloat = 0.0,
                                  delay: TimeInterval = 0.0,
                                  options: AnimationOptions,
                                  animation: @escaping () -> Void,
                                  completion: ((Bool) -> Swift.Void)? = nil) {
    if #available(iOS 17.0, *) {
      UIView.animate(springDuration: duration, bounce: bounce, initialSpringVelocity: initialSpringVelocity, delay: delay, options: options) {
        animation()
      } completion: { finished in
        completion?(finished)
      }
    } else {
      UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 1.0 - bounce, initialSpringVelocity: initialSpringVelocity, options: options) {
        animation()
      } completion: { finished in
        completion?(finished)
      }
    }
  }
  
}
