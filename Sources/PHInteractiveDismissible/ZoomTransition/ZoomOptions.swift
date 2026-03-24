//
//  ZoomOptions.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public struct ZoomOptions {
  var duration: TimeInterval
  var maskCornerRadius: CGFloat
  var minimumScale: CGFloat
  var maskVisualEffect: UIVisualEffect?
  var dimmingColor: UIColor?
  var dimmingVisualEffect: UIBlurEffect?
  
  public init(duration: TimeInterval,
              maskCornerRadius: CGFloat = UIScreen.main.displayCornerRadius,
              minimumScale: CGFloat = 0.5,
              maskVisualEffect: UIVisualEffect? = nil,
              dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.25),
              dimmingVisualEffect: UIBlurEffect? = nil) {
    self.duration = duration
    self.maskCornerRadius = maskCornerRadius
    self.minimumScale = minimumScale
    self.maskVisualEffect = maskVisualEffect
    self.dimmingColor = dimmingColor
    self.dimmingVisualEffect = dimmingVisualEffect
  }
}

extension ZoomOptions {
  public static var `default`: ZoomOptions {
    .init(
      duration: 0.5,
      minimumScale: 0.5,
      maskVisualEffect: nil,
      dimmingColor: UIColor.black.withAlphaComponent(0.25),
      dimmingVisualEffect: nil
    )
  }
}
