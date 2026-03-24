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

  func zoom(to viewController: InteractiveDismissible & ZoomTransitioning,
            from sourceView: UIView,
            sourceRect: CGRect,
            completion: (() -> Void)? = nil) {
    let interactionController = PHZoomInteractivePopInteractionController(viewController: viewController)
    let delegate = PHZoomTransitioningDelegate(interactionController: interactionController)

    viewController._zoomTransitioningDelegate = delegate
    viewController._zoomTransitionSourceView = sourceView
    viewController._zoomTransitionSourceRect = sourceRect == .zero ? sourceView.convert(sourceView.bounds, to: nil) : sourceRect
    viewController.interactiveTransitionManager = delegate
    viewController.transitioningDelegate = delegate
    viewController.modalPresentationStyle = .custom

    present(viewController, animated: true) {
      completion?()
    }
  }
}

extension UIViewController {
  fileprivate struct Holder {
    static var backButtonEnabled: UInt8 = 0
    static var zoomTransitioningDelegate: UInt8 = 0
    static var zoomTransitionSourceRect: UInt8 = 0
    static var zoomTransitionSourceView: UInt8 = 0
  }

  fileprivate final class WeakViewBox {
    weak var value: UIView?

    init(_ value: UIView?) {
      self.value = value
    }
  }
  
  public var backButtonEnabled: Bool {
    get {
      (objc_getAssociatedObject(self, &Holder.backButtonEnabled) as? Bool) ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(self, &Holder.backButtonEnabled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  var _zoomTransitioningDelegate: PHZoomTransitioningDelegate? {
    get {
      objc_getAssociatedObject(self, &Holder.zoomTransitioningDelegate) as? PHZoomTransitioningDelegate
    }
    set {
      objc_setAssociatedObject(self, &Holder.zoomTransitioningDelegate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  var _zoomTransitionSourceRect: CGRect? {
    get {
      (objc_getAssociatedObject(self, &Holder.zoomTransitionSourceRect) as? NSValue)?.cgRectValue
    }
    set {
      let value = newValue.map(NSValue.init(cgRect:))
      objc_setAssociatedObject(self, &Holder.zoomTransitionSourceRect, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  var _zoomTransitionSourceView: UIView? {
    get {
      (objc_getAssociatedObject(self, &Holder.zoomTransitionSourceView) as? WeakViewBox)?.value
    }
    set {
      let box = WeakViewBox(newValue)
      objc_setAssociatedObject(self, &Holder.zoomTransitionSourceView, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}
