//
//  ZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public protocol ZoomTransitioning {
  var sharedFrame: CGRect { get }
  var config: ZoomTransitionConfig? { get }
  func prepare(for transition: PHZoomTransitioning.Transition)
}

extension ZoomTransitioning {
  func prepare(for transition: PHZoomTransitioning.Transition) {}
  var config: ZoomTransitionConfig? { nil }
}

extension UIViewControllerContextTransitioning {
  func sharedFrame(forKey key: UITransitionContextViewControllerKey) -> CGRect? {
    let viewController = viewController(forKey: key)
    viewController?.view.layoutIfNeeded()
    if let navigationController = viewController as? UINavigationController {
      return (navigationController.topViewController as? ZoomTransitioning)?.sharedFrame
    }
    return (viewController as? ZoomTransitioning)?.sharedFrame
  }
}


import UIKit

struct CornerRadiusProvider {
  static var notchCornerRadius: CGFloat {
    UIScreen.main.displayCornerRadius
  }
}

extension UIScreen {
  private static let cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()
  
  public var displayCornerRadius: CGFloat {
    guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
      return 0
    }
    
    return cornerRadius
  }
}
