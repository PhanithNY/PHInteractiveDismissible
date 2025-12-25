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
  var overlayOpacity: CGFloat
  var sourceView: UIView?
  var maskVisualEffect: UIVisualEffect?
  
  public init(duration: TimeInterval,
              maskCornerRadius: CGFloat = UIScreen.main.displayCornerRadius,
              maskVisualEffect: UIVisualEffect?,
              overlayOpacity: CGFloat,
              sourceView: UIView?) {
    self.duration = duration
    self.maskCornerRadius = maskCornerRadius
    self.overlayOpacity = overlayOpacity
    self.maskVisualEffect = maskVisualEffect
    self.sourceView = sourceView
  }
}

extension ZoomTransitionConfig {
  public static var `default`: ZoomTransitionConfig {
    .init(
      duration: 0.5,
      maskVisualEffect: UIBlurEffect(style: .dark),
      overlayOpacity: 0.5,
      sourceView: nil
    )
  }
}
