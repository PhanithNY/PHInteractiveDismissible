//
//  PHZoomTransitioning.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import Foundation
import SwiftUI
import UIKit

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

    private var toolbar: UIBarButtonItem?
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

        // Create and cache snapshot of the source view
        let snapshot = sourceView!.resizableSnapshotView(
            from: sourceView!.bounds, afterScreenUpdates: false, withCapInsets: .zero)!
        self.snapshotView = snapshot

        if let sourceView {
            snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
            snapshot.backgroundColor = sourceView.backgroundColor
        }

        let result = CGAffineTransform.transform(
            parent: toView.frame,
            soChild: toFrame,
            aspectFills: fromFrame
        )

        let transform = result.transform

        let maskFrame = fromFrame.aspectFit(to: toFrame)
        let mask = UIView(frame: maskFrame).then {
            $0.backgroundColor = .red
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
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

        // Position snapshot to match the mask
        snapshot.frame = maskFrame
        toView.addSubview(snapshot)

        // Create blur effect for morphing
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = toView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toView.insertSubview(blurView, belowSubview: snapshot)

        // Calculate morph timing - fade out in first 25% of animation
        let morphDuration = config.duration * 0.25

        if #available(iOS 17.0, *) {
            // Fade out snapshot and blur quickly at the beginning
            UIView.animate(
                springDuration: morphDuration,
                bounce: 0.0,
                initialSpringVelocity: 0.0,
                delay: 0.0,
                options: .curveEaseOut
            ) {
                snapshot.alpha = 0.0
            }
          
          // can remove
          UIView.animate(
            springDuration: config.duration * 0.25, bounce: 0.075, initialSpringVelocity: 10.0,
              delay: 0.0,
              options: .curveEaseInOut
          ) {
            blurView.effect = nil
          }

            // Main zoom animation with subtle bounce
            UIView.animate(
              springDuration: config.duration * 0.75, bounce: 0.075, initialSpringVelocity: 0.0,
                delay: 0.0,
                options: .curveEaseInOut
            ) {
                toView.transform = .identity
                mask.frame = toView.frame
                mask.layer.cornerRadius = self.config.maskCornerRadius
                overlay.layer.opacity = self.config.overlayOpacity
                snapshot.frame = toView.frame
            } completion: { _ in
                self.sourceView?.isHidden = true
                blurView.removeFromSuperview()
                snapshot.removeFromSuperview()
                toView.mask = nil
                overlay.removeFromSuperview()
                placeholder.removeFromSuperview()
                context.completeTransition(true)
            }
            return
        }

        // Fallback for iOS 13-16
        UIView.animate(duration: config.duration, curve: config.curve) { [config] in
            toView.transform = .identity
            mask.frame = toView.frame
            mask.layer.cornerRadius = config.maskCornerRadius
            overlay.layer.opacity = config.overlayOpacity
            snapshot.alpha = 0.0
            snapshot.frame = toView.frame
        } completion: {
            self.sourceView?.isHidden = true
            blurView.removeFromSuperview()
            snapshot.removeFromSuperview()
            toView.mask = nil
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            context.completeTransition(true)
        }

        // Blur animation for older iOS versions
        UIView.animate(
            withDuration: morphDuration,
            delay: 0.0,
            options: .curveEaseOut,
            animations: {
                blurView.effect = nil
            }
        )
    }

    private func animationForDismissal(from context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }

        // Use the cached snapshot from presentation
        let snapshot = snapshotView!
        print(snapshot.superview)
        if let sourceView {
            snapshot.layer.cornerRadius = sourceView.layer.cornerRadius
            if let superviewBackgroundColor = snapshot.superview?.backgroundColor {
                snapshot.backgroundColor = sourceView.backgroundColor?.opaqueColor(
                    over: superviewBackgroundColor)
            } else {
                snapshot.backgroundColor = sourceView.backgroundColor
            }
        }

        let result = CGAffineTransform.transform(
            parent: fromView.frame,
            soChild: fromFrame,
            aspectFills: toFrame
        )

        let mask = UIView(frame: fromView.frame).then {
            $0.backgroundColor = .red
            $0.layer.cornerRadius = config.maskCornerRadius
            $0.layer.masksToBounds = true
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

        // Position snapshot initially invisible
        snapshot.alpha = 0.0
        snapshot.frame = fromFrame
        fromView.addSubview(snapshot)

        let maskFrame = toFrame.aspectFit(to: fromFrame)

        // Create blur effect for morphing
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: nil)
        blurView.frame = fromView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fromView.insertSubview(blurView, belowSubview: snapshot)
        //    fromView.addSubview(blurView)
        //    fromView.addSubview(snapshot)

        // Calculate morph timing - start at 75% of the animation
        let morphDelay = config.duration * 0.25
        let morphDuration = config.duration * 0.75

        if #available(iOS 17.0, *) {
            // Main zoom animation
          
          // can rmeove
//          UIView.animate(
//              springDuration: config.duration / 2,
//              bounce: 0.1,
//              initialSpringVelocity: 10.0,
//              delay: 0.0,
//              options: [.curveEaseInOut, .allowUserInteraction]
//          ) {
//            blurView.effect = blurEffect
//
//          }
          
          UIView.animate(
            springDuration: config.duration * 0.25, bounce: 0.075, initialSpringVelocity: 10.0,
              delay: config.duration * 0.15,
              options: .curveEaseInOut
          ) {
            blurView.effect = blurEffect
          }

          
            UIView.animate(
                springDuration: config.duration,
                bounce: 0.1,
                initialSpringVelocity: 10.0,
                delay: 0.0,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                fromView.transform = result.transform
                mask.frame = maskFrame
                mask.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
                overlay.layer.opacity = 0
                snapshot.frame = maskFrame
                snapshot.layer.cornerRadius = 0

            } completion: { _ in
                self.sourceView?.isHidden = false
                fromView.mask = nil
                blurView.removeFromSuperview()
                snapshot.removeFromSuperview()
                overlay.removeFromSuperview()
                placeholder.removeFromSuperview()
                let isCancelled = context.transitionWasCancelled
                context.completeTransition(!isCancelled)
            }

            // Blur animation: apply blur at 75% mark for morphing effect
//            UIView.animate(
//                springDuration: morphDuration,
//                bounce: 0.0,
//                initialSpringVelocity: 0.0,
//                delay: morphDelay,
//                options: .curveEaseIn
//            ) {
//                blurView.effect = blurEffect
//            }

            // Morph animation: crossfade to snapshot during blur
            UIView.animate(
                springDuration: morphDuration,
                bounce: 0.0,
                initialSpringVelocity: 0.0,
                delay: morphDelay,
                options: .curveLinear
            ) {
                snapshot.alpha = 1.0
            }

            return
        }

        // Fallback for iOS 13-16
        UIView.animate(duration: config.duration, curve: config.curve) { [self] in
            fromView.transform = result.transform
            mask.frame = maskFrame
            mask.layer.cornerRadius = snapshot.layer.cornerRadius / result.scaleFactor
            overlay.layer.opacity = 0
            snapshot.frame = maskFrame
        } completion: {
            self.sourceView?.isHidden = false
            fromView.mask = nil
            blurView.removeFromSuperview()
            snapshot.removeFromSuperview()
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            let isCancelled = context.transitionWasCancelled
            context.completeTransition(!isCancelled)
        }

        // Morph animation for older iOS versions
        UIView.animate(
            withDuration: morphDuration,
            delay: morphDelay,
            options: .curveEaseIn,
            animations: {
                //        blurView.effect = blurEffect
            }
        )

        UIView.animate(
            withDuration: morphDuration,
            delay: morphDelay,
            options: .curveLinear,
            animations: {
                snapshot.alpha = 1.0
            }
        )
    }
}

// MARK: Helpers

extension PHZoomTransitioning {
    private func prepareViewControllers(
        from context: UIViewControllerContextTransitioning,
        for transition: Transition
    ) {
        let fromVC = context.viewController(forKey: .from) as? ZoomTransitioning
        let toVC = context.viewController(forKey: .to) as? ZoomTransitioning
        if let customConfig = fromVC?.config {
            config = customConfig
        }
        fromVC?.prepare(for: transition)
        toVC?.prepare(for: transition)
    }

    private func setup(with context: UIViewControllerContextTransitioning) -> (
        UIView, CGRect, UIView, CGRect
    )? {
        guard let toView = context.viewController(forKey: .to)?.view,
            let fromView = context.viewController(forKey: .from)?.view
        else {
            return nil
        }
        if transition == .present {
            context.containerView.addSubview(toView)
        }
        guard let toFrame = context.sharedFrame(forKey: .to),
            let fromFrame = context.sharedFrame(forKey: .from)
        else {
            return nil
        }
        return (fromView, fromFrame, toView, toFrame)
    }
}

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

extension UIColor {
    /// Returns an opaque color by compositing this color over a background
    /// - Parameter background: The background color (default: white)
    /// - Returns: The composited opaque color
    func opaqueColor(over background: UIColor = .white) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        // Get components of foreground (this color)
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        // Get components of background
        background.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        // Alpha compositing formula: result = foreground * alpha + background * (1 - alpha)
        let r = r1 * a1 + r2 * (1 - a1)
        let g = g1 * a1 + g2 * (1 - a1)
        let b = b1 * a1 + b2 * (1 - a1)

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /// Returns the hex string of this color
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        let red = Int(r * 255)
        let green = Int(g * 255)
        let blue = Int(b * 255)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
