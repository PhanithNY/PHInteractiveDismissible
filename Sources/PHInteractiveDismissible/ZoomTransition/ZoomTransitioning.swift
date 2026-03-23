//
//  ZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public protocol ZoomTransitioning {
  typealias Options = (fromView: UIView, fromRect: CGRect, toView: UIView, toRect: CGRect)
  
  var sharedFrame: CGRect { get }
  var config: ZoomOptions? { get }
  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView?
  func prepare(for transition: PHZoomTransitioning.Transition)
}

public extension ZoomTransitioning {
  var config: ZoomOptions? {
    nil
  }
  
  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView? {
    config?.sourceView
  }
  
  func prepare(for transition: PHZoomTransitioning.Transition) {
    
  }
}

public extension ZoomTransitioning where Self: UIViewController {
  var config: ZoomOptions? {
    return .init(
      duration: 0.4,
      maskVisualEffect: nil,
      dimmingColor: nil,
      dimmingVisualEffect: nil
    )
  }
  
  var sharedFrame: CGRect {
    view.bounds
  }
  
  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView? {
    config?.sourceView
  }
  
  func prepare(for transition: PHZoomTransitioning.Transition) {
    
  }
}

extension UIViewController {
  func resolvedZoomTransitioning() -> ZoomTransitioning? {
    if let navigationController = self as? UINavigationController {
      return navigationController.topViewController?.resolvedZoomTransitioning()
        ?? (navigationController as? ZoomTransitioning)
    }
    
    if let tabBarController = self as? UITabBarController {
      return tabBarController.selectedViewController?.resolvedZoomTransitioning()
        ?? (tabBarController as? ZoomTransitioning)
    }
    
    return self as? ZoomTransitioning
  }
}

extension UIViewControllerContextTransitioning {
  func sharedFrame(forKey key: UITransitionContextViewControllerKey) -> CGRect? {
    viewController(forKey: key)?.resolvedZoomTransitioning()?.sharedFrame
  }
  
  func sourceView(forKey key: UITransitionContextViewControllerKey,
                  transition: PHZoomTransitioning.Transition) -> UIView? {
    viewController(forKey: key)?.resolvedZoomTransitioning()?.sourceView(for: transition)
  }
}
