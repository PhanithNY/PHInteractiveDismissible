//
//  Helper.swift
//  Example
//
//  Created by Phanith Ny on 9/12/25.
//

import PHInteractiveDismissible
import UIKit

extension UINavigationController: PHInteractiveDismissible.InteractiveDismissible {
  public var interactiveTransitionManager: UIViewControllerTransitioningDelegate? {
    get {
      (topViewController as? InteractiveDismissible)?.interactiveTransitionManager
    }
    
    set(newValue) {
      (topViewController as? InteractiveDismissible)?.interactiveTransitionManager = newValue
    }
  }
  
  public var dismissibleScrollView: UIScrollView? {
    (topViewController as? InteractiveDismissible)?.dismissibleScrollView
  }
  
  public var preferredCornerRadius: CGFloat? {
    (topViewController as? InteractiveDismissible)?.preferredCornerRadius ?? 44
  }
}
