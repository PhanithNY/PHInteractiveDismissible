//
//  InteractiveDismissible.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit
import ObjectiveC

private enum InteractiveDismissibleAssociatedKeys {
  static var interactiveTransitionManager: UInt8 = 0
}

public protocol InteractiveDismissible: UIViewController {
  var dismissibleScrollView: UIScrollView? { get }
  var interactiveTransitionManager: UIViewControllerTransitioningDelegate? { get set }
  var preferredCornerRadius: CGFloat? { get }
  func updatePresentationLayout(animated: Bool)
}

public extension InteractiveDismissible {
  var interactiveTransitionManager: UIViewControllerTransitioningDelegate? {
    get {
      objc_getAssociatedObject(self, &InteractiveDismissibleAssociatedKeys.interactiveTransitionManager) as? UIViewControllerTransitioningDelegate
    }
    set {
      objc_setAssociatedObject(self,
                               &InteractiveDismissibleAssociatedKeys.interactiveTransitionManager,
                               newValue,
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  var dismissibleScrollView: UIScrollView? {
    nil
  }
  
  var preferredCornerRadius: CGFloat? {
    if #available(iOS 26.0, *) {
      return CornerRadiusProvider.deviceCornerRadius
    }
    return nil
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

extension UINavigationController: InteractiveDismissible {
  public var dismissibleScrollView: UIScrollView? {
    (topViewController as? InteractiveDismissible)?.dismissibleScrollView
  }

  public var preferredCornerRadius: CGFloat? {
    (topViewController as? InteractiveDismissible)?.preferredCornerRadius
  }
}
