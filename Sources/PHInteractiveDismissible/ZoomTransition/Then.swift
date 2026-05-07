//
//  Then.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 24/12/25.
//

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
