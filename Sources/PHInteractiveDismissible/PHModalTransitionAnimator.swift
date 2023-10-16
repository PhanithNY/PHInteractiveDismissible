//
//  PHModalTransitionAnimator.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public final class PHModalTransitionAnimator: NSObject {
  
  private let presenting: Bool
  
  public init(presenting: Bool) {
    self.presenting = presenting
    super.init()
  }
}

extension PHModalTransitionAnimator: UIViewControllerAnimatedTransitioning {
  
  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.5 }
  
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    if presenting {
      animatePresentation(using: transitionContext)
    } else {
      animateDismissal(using: transitionContext)
    }
  }
  
  private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
    let presentedViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    transitionContext.containerView.addSubview(presentedViewController.view)
    
    let presentedFrame = transitionContext.finalFrame(for: presentedViewController)
    let dismissedFrame = CGRect(x: transitionContext.containerView.bounds.width, y: presentedFrame.minX, width: presentedFrame.width, height: presentedFrame.height)
    presentedViewController.view.frame = dismissedFrame
//    presentedViewController.view.applyObscuredShadow()
    
    let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 1.0) {
      presentedViewController.view.frame = presentedFrame
      presentingViewController.view.frame = CGRect(x: -(0.25 * presentedFrame.width), y: 0, width: presentedFrame.width, height: presentedFrame.height)
    }
    
    animator.addCompletion { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }
    
    animator.startAnimation()
  }
  
  private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    //    transitionContext.containerView.insertSubview(presentingViewController.view, at: 0)
    
    let presentedFrame = transitionContext.finalFrame(for: presentedViewController)
    let dismissedFrame = CGRect(x: transitionContext.containerView.bounds.width, y: presentedFrame.minY, width: presentedFrame.width, height: presentedFrame.height)
    
    let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 1.0) {
      presentingViewController.view.frame = CGRect(x: 0, y: 0, width: presentedFrame.width, height: presentedFrame.height)
      presentedViewController.view.frame = dismissedFrame
    }
    
    animator.addCompletion { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }
    
    animator.startAnimation()
  }
}
