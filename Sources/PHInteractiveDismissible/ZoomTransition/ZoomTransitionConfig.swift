//
//  ZoomTransitionConfig.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public struct ZoomTransitionConfig {
  var duration: TimeInterval
  var maskCornerRadius: CGFloat
  var sourceView: UIView?
  var maskVisualEffect: UIVisualEffect?
  var dimmingColor: UIColor?
  var dimmingVisualEffect: UIBlurEffect?
  
  public init(duration: TimeInterval,
              maskCornerRadius: CGFloat = UIScreen.main.displayCornerRadius,
              maskVisualEffect: UIVisualEffect? = nil,
              dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.25),
              dimmingVisualEffect: UIBlurEffect? = nil,
              sourceView: UIView?) {
    self.duration = duration
    self.maskCornerRadius = maskCornerRadius
    self.maskVisualEffect = maskVisualEffect
    self.sourceView = sourceView
    self.dimmingColor = dimmingColor
    self.dimmingVisualEffect = dimmingVisualEffect
  }
}

extension ZoomTransitionConfig {
  public static var `default`: ZoomTransitionConfig {
    .init(
      duration: 0.5,
      maskVisualEffect: nil,
      dimmingColor: UIColor.black.withAlphaComponent(0.25),
      dimmingVisualEffect: nil,
      sourceView: nil
    )
  }
}
