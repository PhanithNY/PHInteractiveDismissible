//
//  PHZoomTransitioningDelegate.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public final class PHZoomTransitioningDelegate: NSObject {
  
  private var interactionController: InteractiveTransitioning?
  private var sourceView: UIView
  private lazy var transitionAnimator: PHZoomTransitioning = .init(sourceView: sourceView)
  
  public init(interactionController: InteractiveTransitioning?, sourceView: UIView) {
    self.interactionController = interactionController
    self.sourceView = sourceView
  }
}

extension PHZoomTransitioningDelegate: UIViewControllerTransitioningDelegate {
  
  public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    PHZoomPresentationController(presentedViewController: presented, presenting: presenting)
  }
  
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    transitionAnimator.transition = .present
    return transitionAnimator
  }
  
  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    transitionAnimator.transition = .dismiss
    return transitionAnimator
  }
  
  public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    guard let interactionController = interactionController, interactionController.interactionInProgress else {
      return nil
    }
    return interactionController
  }
}
