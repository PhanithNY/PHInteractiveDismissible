// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

extension UINavigationController: InteractivePresentable {
  public var interactiveTransitionManager: UIViewControllerTransitioningDelegate? {
    get {
      (topViewController as? InteractivePresentable)?.interactiveTransitionManager
    }
    
    set(newValue) {
      (topViewController as? InteractivePresentable)?.interactiveTransitionManager = newValue
    }
  }
  
  public var dismissibleScrollView: UIScrollView? {
    (topViewController as? InteractivePresentable)?.dismissibleScrollView
  }
  
  public func updatePresentationLayout(animated: Bool) {
    (topViewController as? InteractivePresentable)?.updatePresentationLayout(animated: animated)
  }
}

public extension UIViewController {
  final func present(_ viewController: InteractivePresentable,
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
    static var _backButtonEnabled = [String: Bool]()
  }
  
  public var backButtonEnabled: Bool {
    get {
      Holder._backButtonEnabled[self.debugDescription] ?? false
    }
    set(newValue) {
      Holder._backButtonEnabled[self.debugDescription] = newValue
    }
  }
}
