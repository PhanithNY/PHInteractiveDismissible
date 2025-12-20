//
//  PHZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

extension UIView: NSSecureCoding {
  public static var supportsSecureCoding: Bool {
    true
  }
}

public class PHZoomTransitioning: NSObject {
  
  // MARK: Inner types
  
  public enum Transition {
    case present
    case dismiss
  }
  
  // MARK: Public properties
  
  public var transition: Transition = .present
  
  public var sourceView: UIView?
  private var snapshotView: UIView?
  
  public init(sourceView: UIView?) {
    self.sourceView = sourceView
  }
  
  // MARK: Private properties
  
  private var config: ZoomTransitionConfig = .default
}

// MARK: - UIViewControllerAnimatedTransitioning

extension PHZoomTransitioning: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    config.duration
  }
  
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    prepareViewControllers(from: transitionContext, for: transition)
    
    switch transition {
    case .present:
      animationForPresentation(from: transitionContext)
      
    case .dismiss:
      animationForDismissal(from: transitionContext)
    }
  }
}

// MARK: - Animations

extension PHZoomTransitioning {
  private func animationForPresentation(from context: UIViewControllerContextTransitioning) {
    guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
      context.completeTransition(false)
      return
    }
    
//    sourceView?.window?.layoutIfNeeded()
//    sourceView?.layoutIfNeeded()
    let rect = sourceView!.convert(sourceView!.bounds, to: nil)
    let view = sourceView!.resizableSnapshotView(from: sourceView!.bounds, afterScreenUpdates: false, withCapInsets: .zero)!
    self.snapshotView = view
    
    let imageView = view
    if let sourceView {
      imageView.layer.cornerRadius = sourceView.layer.cornerRadius
      imageView.backgroundColor = sourceView.backgroundColor
    }
    
    let transform: CGAffineTransform = .transform(
      parent: toView.frame,
      soChild: toFrame,
      aspectFills: fromFrame
    )
    
    let maskFrame = fromFrame.aspectFit(to: toFrame)
    let mask = UIView(frame: maskFrame).then {
      $0.backgroundColor = .red
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = config.maskCornerRadius * UIScreen.main.scale
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = .black
      $0.layer.opacity = 0
      $0.frame = fromView.frame
    }
    
    let placeholder = UIView().then {
      $0.backgroundColor = config.placeholderColor
      $0.frame = fromFrame
    }
    
    toView.mask = mask
    toView.transform = transform
    fromView.addSubview(placeholder)
    fromView.addSubview(overlay)
    
    // testing
    imageView.frame = maskFrame
    toView.addSubview(imageView)

    if #available(iOS 18.0, *) {
      UIView.animate(withDuration: 0.1) {
        imageView.alpha = 0.0
      }
      
      UIView.animate(springDuration: config.duration, bounce: 0.05, initialSpringVelocity: 0.0, delay: 0.0, options: .curveEaseInOut) {
        toView.transform = .identity
        mask.frame = toView.frame
        mask.layer.cornerRadius = config.maskCornerRadius
        overlay.layer.opacity = config.overlayOpacity
        print(config.maskCornerRadius)
        
        self.sourceView?.isHidden = true
//        imageView.layer.cornerRadius = config.maskCornerRadius
//        imageView.alpha = 0.0
        imageView.frame = toView.frame
      } completion: { _ in
        self.sourceView?.isHidden = true
        imageView.removeFromSuperview()
        toView.mask = nil
        overlay.removeFromSuperview()
        placeholder.removeFromSuperview()
        context.completeTransition(true)
      }
      return
    }
    
    UIView.animate(duration: config.duration, curve: config.curve) { [config] in
      toView.transform = .identity
      mask.frame = toView.frame
      mask.layer.cornerRadius = config.maskCornerRadius
      overlay.layer.opacity = config.overlayOpacity
      print(config.maskCornerRadius)
      
      imageView.alpha = 0.0
      imageView.frame = toView.frame
      self.sourceView?.alpha = 0.0
    } completion: {
      self.sourceView?.alpha = 0.0
      imageView.removeFromSuperview()
      toView.mask = nil
      overlay.removeFromSuperview()
      placeholder.removeFromSuperview()
      context.completeTransition(true)
    }
  }
  
  private func animationForDismissal(from context: UIViewControllerContextTransitioning) {
    guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
      context.completeTransition(false)
      return
    }
    
    let rect = sourceView!.convert(sourceView!.bounds, to: nil)
    let view = sourceView!.resizableSnapshotView(from: sourceView!.bounds, afterScreenUpdates: false, withCapInsets: .zero)!
    
    let imageView = snapshotView!//view
    if let sourceView {
      imageView.layer.cornerRadius = sourceView.layer.cornerRadius
      imageView.backgroundColor = sourceView.backgroundColor
    }
    
    let transform: CGAffineTransform = .transform(
      parent: fromView.frame,
      soChild: fromFrame,
      aspectFills: toFrame
    )
    
    let mask = UIView(frame: fromView.frame).then {
      $0.backgroundColor = .black
      $0.layer.cornerRadius = config.maskCornerRadius
    }
    
    let overlay = UIView().then {
      $0.backgroundColor = .black
      $0.layer.opacity = config.overlayOpacity
      $0.frame = toView.frame
    }
    
    let placeholder = UIView().then {
      $0.backgroundColor = config.placeholderColor
      $0.frame = toFrame
    }
    
    fromView.mask = mask
    toView.addSubview(placeholder)
    toView.addSubview(overlay)
    
    // testing
    imageView.alpha = 0.0
    imageView.frame = fromFrame
    fromView.addSubview(imageView)
    
    let maskFrame = toFrame.aspectFit(to: fromFrame)

    if #available(iOS 18.0, *) {
      UIView.animate(withDuration: 0.1, delay: config.duration - 0.1*1.5) {
        imageView.alpha = 1.0
      }
      
      UIView.animate(springDuration: config.duration, bounce: 0.15, initialSpringVelocity: 0.0, delay: 0.0, options: .curveEaseInOut) {
        fromView.transform = transform
        mask.frame = maskFrame
        mask.layer.cornerRadius = config.maskCornerRadius * UIScreen.main.scale
        overlay.layer.opacity = 0
        
        imageView.frame = maskFrame
//        imageView.layer.cornerRadius = config.maskCornerRadius * UIScreen.main.scale
//        imageView.alpha = 1.0
      } completion: { _ in
        self.sourceView?.isHidden = false
        overlay.removeFromSuperview()
        placeholder.removeFromSuperview()
        let isCancelled = context.transitionWasCancelled
        context.completeTransition(!isCancelled)
      }
      return
    }
    
    UIView.animate(duration: config.duration, curve: config.curve) { [self] in
      fromView.transform = transform
      mask.frame = maskFrame
      mask.layer.cornerRadius = config.maskCornerRadius * UIScreen.main.scale
      overlay.layer.opacity = 0
      sourceView?.alpha = 1.0
    } completion: {
      overlay.removeFromSuperview()
      placeholder.removeFromSuperview()
      let isCancelled = context.transitionWasCancelled
      context.completeTransition(!isCancelled)
    }
  }
}

// MARK: Helpers

extension PHZoomTransitioning {
  private func prepareViewControllers(from context: UIViewControllerContextTransitioning,
                                      for transition: Transition) {
    let fromVC = context.viewController(forKey: .from) as? ZoomTransitioning
    let toVC = context.viewController(forKey: .to) as? ZoomTransitioning
    if let customConfig = fromVC?.config {
      config = customConfig
    }
    fromVC?.prepare(for: transition)
    toVC?.prepare(for: transition)
  }
  
  private func setup(with context: UIViewControllerContextTransitioning) -> (UIView, CGRect, UIView, CGRect)? {
    guard let toView = context.viewController(forKey: .to)?.view,
          let fromView = context.viewController(forKey: .from)?.view else {
      return nil
    }
    if transition == .present {
      context.containerView.addSubview(toView)
    } else {
//      context.containerView.insertSubview(toView, belowSubview: fromView)
    }
    guard let toFrame = context.sharedFrame(forKey: .to),
          let fromFrame = context.sharedFrame(forKey: .from) else {
      return nil
    }
    return (fromView, fromFrame, toView, toFrame)
  }
}

import Foundation
#if !os(Linux)
import CoreGraphics
#endif
#if os(iOS) || os(tvOS)
import UIKit.UIGeometry
#endif

public protocol Then {}

extension Then where Self: Any {
  
  /// Makes it available to set properties with closures just after initializing and copying the value types.
  ///
  ///     let frame = CGRect().with {
  ///       $0.origin.x = 10
  ///       $0.size.width = 100
  ///     }
  @inlinable
  public func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
    var copy = self
    try block(&copy)
    return copy
  }
  
  /// Makes it available to execute something with closures.
  ///
  ///     UserDefaults.standard.do {
  ///       $0.set("devxoul", forKey: "username")
  ///       $0.set("devxoul@gmail.com", forKey: "email")
  ///       $0.synchronize()
  ///     }
  @inlinable
  public func `do`(_ block: (Self) throws -> Void) rethrows {
    try block(self)
  }
  
}

extension Then where Self: AnyObject {
  
  /// Makes it available to set properties with closures just after initializing.
  ///
  ///     let label = UILabel().then {
  ///       $0.textAlignment = .center
  ///       $0.textColor = UIColor.black
  ///       $0.text = "Hello, World!"
  ///     }
  @inlinable
  public func then(_ block: (Self) throws -> Void) rethrows -> Self {
    try block(self)
    return self
  }
  
}

extension NSObject: Then {}

#if !os(Linux)
extension CGPoint: Then {}
extension CGRect: Then {}
extension CGSize: Then {}
extension CGVector: Then {}
#endif

extension Array: Then {}
extension Dictionary: Then {}
extension Set: Then {}

#if os(iOS) || os(tvOS)
extension UIEdgeInsets: Then {}
extension UIOffset: Then {}
extension UIRectEdge: Then {}
#endif
// swiftlint:enable all

import UIKit



fileprivate protocol MarqueeViewCopyable {
  func copyMarqueeView() -> UIView
}

extension UIView: MarqueeViewCopyable {
  @objc
  open func copyMarqueeView() -> UIView {
    if let copiedView = try? self.copyObject() {
      return copiedView
    } else {
      let archivedData = NSKeyedArchiver.archivedData(withRootObject: self)
      let copyView = NSKeyedUnarchiver.unarchiveObject(with: archivedData) as! UIView
      return copyView
    }
  }
}

extension UIView {
  func copyObject<T: UIView>() throws -> T? {
    let data = try NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)
    return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
  }
}
