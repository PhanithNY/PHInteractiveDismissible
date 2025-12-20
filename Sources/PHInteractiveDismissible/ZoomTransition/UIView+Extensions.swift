//
//  UIView+Extensions.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit
import SwiftUI

extension UIView {
  var frameInWindow: CGRect? {
    superview?.convert(frame, to: nil)
  }
  
  static func animate(
    duration: TimeInterval,
    curve: CAMediaTimingFunction? = nil,
    options: UIView.AnimationOptions = [],
    animations: @escaping () -> Void,
    completion: (() -> Void)? = nil
  ) {
    if #available(iOS 26.0, *) {
      CATransaction.begin()
      CATransaction.setAnimationTimingFunction(curve)
      
      UIView.animate(bounce: 0.1, initialSpringVelocity: 10, delay: 0, options: options) {
        animations()
      } completion: { _ in
        completion?()
      }
      CATransaction.commit()
      return
    }
    
    CATransaction.begin()
    CATransaction.setAnimationTimingFunction(curve)
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: options,
      animations: animations,
      completion: { _ in completion?() }
    )
    CATransaction.commit()
  }
}
