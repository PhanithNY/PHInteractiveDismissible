//
//  PHModalTransitionManager.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public final class PHModalTransitionManager: NSObject {
  
  private var interactionController: InteractiveTransitioning?
  
  public init(interactionController: InteractiveTransitioning?) {
    self.interactionController = interactionController
  }
}

extension PHModalTransitionManager: UIViewControllerTransitioningDelegate {
  
  public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    return PHModalPresentationController(presentedViewController: presented, presenting: presenting)
  }
  
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return PHModalTransitionAnimator(presenting: true)
  }
  
  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return PHModalTransitionAnimator(presenting: false)
  }
  
  public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    guard let interactionController = interactionController, interactionController.interactionInProgress else {
      return nil
    }
    return interactionController
  }
}
