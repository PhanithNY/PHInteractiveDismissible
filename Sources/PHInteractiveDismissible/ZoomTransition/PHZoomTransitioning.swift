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
  
  public var sourceView: UIView?
  private var snapshotView: UIView?
  private var config: ZoomTransitionConfig = .default
  
  public init(sourceView: UIView?) {
    self.sourceView = sourceView
  }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension PHZoomTransitioning: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
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
    guard let sourceView,
          let snapshot = sourceView.resizableSnapshotView(from: sourceView.bounds, afterScreenUpdates: false, withCapInsets: .zero) else {
      return
    }
    snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
    snapshot.backgroundColor = sourceView.backgroundColor
    snapshotView = snapshot
    
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
    let mask = UIView(frame: maskFrame).then {
      $0.backgroundColor = .red
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = .black
      $0.layer.opacity = 0
      $0.frame = fromView.frame
    }
    
    let placeholder = UIView().then {
      $0.backgroundColor = config.placeholderColor
      $0.frame = fromFrame
    }
    
    toView.mask = mask
    toView.transform = transform
    fromView.addSubview(placeholder)
    fromView.addSubview(overlay)
    
    // Position snapshot to match the mask
    snapshot.frame = maskFrame
    toView.addSubview(snapshot)
    
    // Create blur effect for morphing
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = toView.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    toView.insertSubview(blurView, belowSubview: snapshot)
    toView.addSubview(blurView)
    
    // Calculate morph timing - fade out in first 25% of animation
    let morphDuration = config.duration * 0.25
    
    if #available(iOS 17.0, *) {
      
      // Fade out snapshot and blur quickly at the beginning
      UIView.animate(
        springDuration: morphDuration,
        bounce: 0.0,
        initialSpringVelocity: 10.0,
        delay: 0.0,
        options: .curveEaseInOut
      ) {
        snapshot.alpha = 0.0
      }
      
      UIView.animate(
        springDuration: morphDuration,
        bounce: 0.075,
        initialSpringVelocity: 0.0,
        delay: config.duration * 0.15,
        options: .curveEaseInOut
      ) {
        blurView.effect = nil
      }
      
      // Main zoom animation with subtle bounce
      UIView.animate(
        springDuration: config.duration * 0.75,
        bounce: 0.075,
        initialSpringVelocity: 0.0,
        delay: 0.0,
        options: .curveEaseInOut
      ) {
        toView.transform = .identity
        mask.frame = toView.frame
        mask.layer.cornerRadius = self.config.maskCornerRadius
        overlay.layer.opacity = self.config.overlayOpacity
        snapshot.frame = toView.frame
      } completion: { _ in
        self.sourceView?.isHidden = true
        blurView.removeFromSuperview()
        snapshot.removeFromSuperview()
        toView.mask = nil
        overlay.removeFromSuperview()
        placeholder.removeFromSuperview()
        context.completeTransition(true)
      }
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
    
    // Use the cached snapshot from presentation
    let snapshot = snapshotView!
    if let sourceView {
      snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
      if let superviewBackgroundColor = snapshot.superview?.backgroundColor {
        snapshot.backgroundColor = sourceView.backgroundColor?.opaqueColor(
          over: superviewBackgroundColor)
      } else {
        snapshot.backgroundColor = sourceView.backgroundColor
      }
    }
    
    let result = CGAffineTransform.transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    let mask = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .black
      $0.layer.cornerRadius = config.maskCornerRadius
      $0.layer.masksToBounds = true
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = .black
      $0.layer.opacity = config.overlayOpacity
      $0.frame = toView.frame
    }
    
    let placeholder = UIView().then {
      $0.backgroundColor = config.placeholderColor
      $0.frame = toFrame
    }
    
    fromView.mask = mask
    toView.addSubview(placeholder)
    toView.addSubview(overlay)
    
    // Position snapshot initially invisible
    snapshot.alpha = 0.0
    snapshot.frame = fromFrame
    fromView.addSubview(snapshot)
    
    let maskFrame = toFrame.aspectFit(to: fromFrame)
    
    // Create blur effect for morphing
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurView = UIVisualEffectView(effect: nil)
    blurView.frame = fromView.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    fromView.insertSubview(blurView, belowSubview: snapshot)
    
    // Calculate morph timing - start at 75% of the animation
    let morphDelay = config.duration * 0.25
    let morphDuration = config.duration * 0.75
    
    if #available(iOS 17.0, *) {
      
      UIView.animate(
        springDuration: config.duration * 0.25,
        bounce: 0.075,
        initialSpringVelocity: 10.0,
        delay: config.duration * 0.15,
        options: .curveEaseInOut
      ) {
        blurView.effect = blurEffect
      }
      
      UIView.animate(
        springDuration: config.duration,
        bounce: 0.1,
        initialSpringVelocity: 10.0,
        delay: 0.0,
        options: [.curveEaseInOut, .allowUserInteraction]
      ) {
        fromView.transform = result.transform
        mask.frame = maskFrame
        mask.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
        overlay.layer.opacity = 0
        snapshot.frame = maskFrame
        snapshot.layer.cornerRadius = 0
        
      } completion: { _ in
        self.sourceView?.isHidden = false
        fromView.mask = nil
        blurView.removeFromSuperview()
        snapshot.removeFromSuperview()
        overlay.removeFromSuperview()
        placeholder.removeFromSuperview()
        let isCancelled = context.transitionWasCancelled
        context.completeTransition(!isCancelled)
      }
      
      // Morph animation: crossfade to snapshot during blur
      UIView.animate(
        springDuration: morphDuration,
        bounce: 0.0,
        initialSpringVelocity: 0.0,
        delay: morphDelay,
        options: .curveLinear
      ) {
        snapshot.alpha = 1.0
      }
    }
  }
}

// MARK: Helpers

extension PHZoomTransitioning {
  private func prepareViewControllers(from context: UIViewControllerContextTransitioning,
                                      for transition: Transition) {
    if let fromVC = context.viewController(forKey: .from) as? ZoomTransitioning,
       let customConfig = fromVC.config {
      config = customConfig
      fromVC.prepare(for: transition)
    }
    
    let toVC = context.viewController(forKey: .to) as? ZoomTransitioning
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
