//
//  InteractiveDismissible.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public protocol InteractiveDismissible: UIViewController {
  var dismissibleScrollView: UIScrollView? { get }
  var interactiveTransitionManager: UIViewControllerTransitioningDelegate? { get set }
  var preferredCornerRadius: CGFloat? { get }
  func updatePresentationLayout(animated: Bool)
}

public extension InteractiveDismissible {
  var dismissibleScrollView: UIScrollView? {
    nil
  }
  
  var preferredCornerRadius: CGFloat? {
    nil
  }
  
  func updatePresentationLayout(animated: Bool = false) {
    presentationController?.containerView?.setNeedsLayout()
    
    switch animated {
    case true:
      UIView.animate(withDuration: 0.3, 
                     delay: 0.0,
                     usingSpringWithDamping: 1.0,
                     initialSpringVelocity: 0.0,
                     options: .allowUserInteraction,
                     animations: {
        self.presentationController?.containerView?.layoutIfNeeded()
      }, completion: nil)
      
    case false:
      presentationController?.containerView?.layoutIfNeeded()
    }
  }
}
