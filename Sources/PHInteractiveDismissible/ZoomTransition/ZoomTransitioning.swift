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
  func prepare(for transition: PHZoomTransitioning.Transition)
}

public extension ZoomTransitioning {
  var config: ZoomOptions? {
    nil
  }
  
  func prepare(for transition: PHZoomTransitioning.Transition) {
    
  }
}

public extension ZoomTransitioning where Self: UIViewController {
  var config: ZoomOptions? {
    nil
  }
  
  var sharedFrame: CGRect {
    view.bounds
  }
  
  func prepare(for transition: PHZoomTransitioning.Transition) {
    
  }
}

extension UIViewControllerContextTransitioning {
  func sharedFrame(forKey key: UITransitionContextViewControllerKey) -> CGRect? {
    let viewController = viewController(forKey: key)
//    viewController?.view.layoutIfNeeded()
    if let navigationController = viewController as? UINavigationController {
      return (navigationController.topViewController as? ZoomTransitioning)?.sharedFrame
    }
    return (viewController as? ZoomTransitioning)?.sharedFrame
  }
}
