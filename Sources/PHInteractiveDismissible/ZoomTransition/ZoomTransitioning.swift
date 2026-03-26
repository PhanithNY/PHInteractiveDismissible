//
//  ZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public protocol ZoomTransitioning {
  typealias Options = (fromView: UIView, fromRect: CGRect, toView: UIView, toRect: CGRect)
  
  var zoomOption: ZoomOptions? { get }
  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView?
  func prepare(for transition: PHZoomTransitioning.Transition)
}

public extension ZoomTransitioning {
  var zoomOption: ZoomOptions? {
    nil
  }
  
  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView? {
    nil
  }
  
  func prepare(for transition: PHZoomTransitioning.Transition) {
    
  }
}

public extension ZoomTransitioning where Self: UIViewController {
  var zoomOption: ZoomOptions? {
    return .init(
      duration: 0.4,
      maskVisualEffect: nil,
      dimmingColor: nil,
      dimmingVisualEffect: nil
    )
  }

  func sourceView(for transition: PHZoomTransitioning.Transition) -> UIView? {
    nil
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
  func synchronizeZoomTransitionLayout() {
    containerView.layoutIfNeeded()

    [viewController(forKey: .from), viewController(forKey: .to)].forEach { viewController in
      viewController?.view.setNeedsLayout()
      viewController?.view.layoutIfNeeded()
      viewController?.view.window?.layoutIfNeeded()
    }
  }
  
  func zoomRect(forKey key: UITransitionContextViewControllerKey,
                transition: PHZoomTransitioning.Transition) -> CGRect? {
    let controller = viewController(forKey: key)

    switch (transition, key) {
    case (.present, .from):
      return sourceRect(for: controller, transition: transition)
        ?? sourceRect(for: viewController(forKey: .to), transition: transition)
      
    case (.present, .to):
      return presentedRect(for: controller)
      
    case (.dismiss, .from):
      return presentedRect(for: controller)
      
    case (.dismiss, .to):
      return sourceRect(for: controller, transition: transition)
        ?? sourceRect(for: viewController(forKey: .from), transition: transition)
      
    default:
      return nil
    }
  }
  
  func sourceView(forKey key: UITransitionContextViewControllerKey,
                  transition: PHZoomTransitioning.Transition) -> UIView? {
    let controller = viewController(forKey: key)

    if let sourceView = resolvedSourceView(for: controller, transition: transition) {
      return sourceView
    }

    switch (transition, key) {
    case (.present, .from):
      return resolvedSourceView(for: viewController(forKey: .to), transition: transition)
      
    case (.dismiss, .to):
      return resolvedSourceView(for: viewController(forKey: .from), transition: transition)
      
    default:
      return nil
    }
  }
  
  private func sourceRect(for controller: UIViewController?,
                          transition: PHZoomTransitioning.Transition) -> CGRect? {
    if let sourceView = resolvedSourceView(for: controller, transition: transition) {
      synchronizeZoomTransitionLayout()
      controller?.view.layoutIfNeeded()
      sourceView.superview?.layoutIfNeeded()
      sourceView.window?.layoutIfNeeded()
      return sourceView.convert(sourceView.bounds, to: containerView)
    }

    guard transition == .present else {
      return nil
    }

    if let frame = controller?._zoomTransitionSourceRect {
      return frame
    }

    return nil
  }

  private func presentedRect(for controller: UIViewController?) -> CGRect? {
    guard let view = controller?.view else {
      return nil
    }

    return view.convert(view.bounds, to: containerView)
  }

  private func resolvedSourceView(for controller: UIViewController?,
                                  transition: PHZoomTransitioning.Transition) -> UIView? {
    if let sourceView = controller?.resolvedZoomTransitioning()?.sourceView(for: transition) {
      return sourceView
    }

    if let sourceView = controller?._zoomTransitionSourceViewProvider?() {
      return sourceView
    }

    return controller?._zoomTransitionSourceView
  }
}
