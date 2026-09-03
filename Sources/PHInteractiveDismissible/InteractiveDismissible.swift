//
//  InteractiveDismissible.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit
import ObjectiveC

private enum InteractiveDismissibleAssociatedKeys {
  static var interactiveTransitionManager: UInt8 = 0
}

public protocol InteractiveDismissible: UIViewController {
  var dismissibleScrollView: UIScrollView? { get }
  /// Views whose touches must not start an interactive dismissal gesture.
  /// A touch in any descendant of one of these views is excluded as well.
  var exclusiveViews: [UIView] { get }
  var interactiveTransitionManager: UIViewControllerTransitioningDelegate? { get set }
  var preferredCornerRadius: CGFloat? { get }
  /// Return `false` to prevent the interactive dismiss gesture from starting.
  /// Return `true` (or leave `nil`) to allow it as normal.
  /// Use this to block dismissal during sensitive flows, e.g. PIN verification.
  var interactiveDismissShouldBegin: (() -> Bool)? { get }
  func updatePresentationLayout(animated: Bool)
}

public extension InteractiveDismissible {
  var interactiveTransitionManager: UIViewControllerTransitioningDelegate? {
    get {
      objc_getAssociatedObject(self, &InteractiveDismissibleAssociatedKeys.interactiveTransitionManager) as? UIViewControllerTransitioningDelegate
    }
    set {
      objc_setAssociatedObject(self,
                               &InteractiveDismissibleAssociatedKeys.interactiveTransitionManager,
                               newValue,
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  var dismissibleScrollView: UIScrollView? {
    nil
  }

  var exclusiveViews: [UIView] {
    []
  }

  var interactiveDismissShouldBegin: (() -> Bool)? {
    nil
  }
  
  var preferredCornerRadius: CGFloat? {
    if #available(iOS 26.0, *) {
      return CornerRadiusProvider.deviceCornerRadius
    }
    return nil
  }
  
  func updatePresentationLayout(animated: Bool = false) {
    presentationController?.containerView?.setNeedsLayout()
    
    switch animated {
    case true:
      UIView.animate(withDuration: 0.3, 
                     delay: 0.0,
                     usingSpringWithDamping: 1.0,
                     initialSpringVelocity: 0.0,
                     options: .allowUserInteraction,
                     animations: {
        self.presentationController?.containerView?.layoutIfNeeded()
      }, completion: nil)
      
    case false:
      presentationController?.containerView?.layoutIfNeeded()
    }
  }
}

extension InteractiveDismissible {
  /// Checks only the touched view's ancestor chain. Building an identity set makes the lookup
  /// O(exclusiveViews.count + view-depth), and this runs once when UIKit offers a touch to a
  /// recognizer rather than during interactive frame rendering.
  internal func shouldReceiveInteractiveDismissTouch(from touchedView: UIView?) -> Bool {
    guard let touchedView else {
      return true
    }

    let exclusiveViews = exclusiveViews
    guard !exclusiveViews.isEmpty else {
      return true
    }

    var exclusiveViewIdentifiers = Set<ObjectIdentifier>()
    exclusiveViewIdentifiers.reserveCapacity(exclusiveViews.count)
    for exclusiveView in exclusiveViews {
      exclusiveViewIdentifiers.insert(ObjectIdentifier(exclusiveView))
    }

    var candidateView: UIView? = touchedView
    while let candidate = candidateView {
      if exclusiveViewIdentifiers.contains(ObjectIdentifier(candidate)) {
        return false
      }
      candidateView = candidate.superview
    }

    return true
  }
}

extension UINavigationController: InteractiveDismissible {
  public var dismissibleScrollView: UIScrollView? {
    (topViewController as? InteractiveDismissible)?.dismissibleScrollView
  }

  public var exclusiveViews: [UIView] {
    (topViewController as? InteractiveDismissible)?.exclusiveViews ?? []
  }

  public var preferredCornerRadius: CGFloat? {
    (topViewController as? InteractiveDismissible)?.preferredCornerRadius
  }

  public var interactiveDismissShouldBegin: (() -> Bool)? {
    (topViewController as? InteractiveDismissible)?.interactiveDismissShouldBegin
  }
}
