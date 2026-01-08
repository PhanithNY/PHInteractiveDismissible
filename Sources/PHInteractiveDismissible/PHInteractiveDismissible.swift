// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import ObjectiveC

public extension UIViewController {
  final func present(_ viewController: InteractiveDismissible,
               dismissalType: InteractiveDismissalType,
               animated: Bool = true,
               completion: (() -> Void)? = nil) {
    
    let interactionController: InteractiveTransitioning?
    switch dismissalType {
    case .none:
      interactionController = nil
      
    case .interactive:
      interactionController = InteractivePopInteractionController(viewController: viewController)
    }
    
    let transitionManager = PHModalTransitionManager(interactionController: interactionController)
    viewController.interactiveTransitionManager = transitionManager
    viewController.transitioningDelegate = transitionManager
    viewController.modalPresentationStyle = .custom
    present(viewController, animated: animated) {
      completion?()
    }
  }
}

extension UIViewController {
  fileprivate struct Holder {
    static var backButtonEnabled: UInt8 = 0
  }
  
  public var backButtonEnabled: Bool {
    get {
      (objc_getAssociatedObject(self, &Holder.backButtonEnabled) as? Bool) ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(self, &Holder.backButtonEnabled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}
