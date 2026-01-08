//
//  Helper.swift
//  Example
//
//  Created by Phanith Ny on 9/12/25.
//

import PHInteractiveDismissible
import UIKit
import ObjectiveC

extension UINavigationController: PHInteractiveDismissible.InteractiveDismissible {
  private struct AssociatedKeys {
    static var interactiveTransitionManager: UInt8 = 0
  }

  public var interactiveTransitionManager: UIViewControllerTransitioningDelegate? {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.interactiveTransitionManager) as? UIViewControllerTransitioningDelegate
    }
    
    set(newValue) {
      objc_setAssociatedObject(self, &AssociatedKeys.interactiveTransitionManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public var dismissibleScrollView: UIScrollView? {
    (topViewController as? InteractiveDismissible)?.dismissibleScrollView
  }
  
  public var preferredCornerRadius: CGFloat? {
    (topViewController as? InteractiveDismissible)?.preferredCornerRadius ?? 44
  }
}
