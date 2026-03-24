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
  func sharedFrame(forKey key: UITransitionContextViewControllerKey,
                   transition: PHZoomTransitioning.Transition) -> CGRect? {
    let controller = viewController(forKey: key)

    if let frame = controller?.resolvedZoomTransitioning()?.sharedFrame {
      return frame
    }

    if let frame = controller?._zoomTransitionSourceRect {
      return frame
    }

    switch (transition, key) {
    case (.present, .from):
      return viewController(forKey: .to)?._zoomTransitionSourceRect
    case (.dismiss, .to):
      return viewController(forKey: .from)?._zoomTransitionSourceRect
    default:
      return nil
    }
  }
  
  func sourceView(forKey key: UITransitionContextViewControllerKey,
                  transition: PHZoomTransitioning.Transition) -> UIView? {
    let controller = viewController(forKey: key)

    if let sourceView = controller?.resolvedZoomTransitioning()?.sourceView(for: transition) {
      return sourceView
    }

    if let sourceView = controller?._zoomTransitionSourceView {
      return sourceView
    }

    switch (transition, key) {
    case (.present, .from):
      return viewController(forKey: .to)?._zoomTransitionSourceView
    case (.dismiss, .to):
      return viewController(forKey: .from)?._zoomTransitionSourceView
    default:
      return nil
    }
  }
}
