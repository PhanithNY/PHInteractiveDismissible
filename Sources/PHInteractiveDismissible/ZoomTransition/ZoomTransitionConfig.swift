//
//  ZoomTransitionConfig.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public struct ZoomTransitionConfig {
  var duration: CGFloat
  var curve: CAMediaTimingFunction
  var maskCornerRadius: CGFloat
  var overlayOpacity: Float
  var interactionScaleFactor: CGFloat = .zero
  var placeholderColor: UIColor
  var sourceView: UIView?
  
  public init(duration: CGFloat, curve: CAMediaTimingFunction, maskCornerRadius: CGFloat, overlayOpacity: Float, interactionScaleFactor: CGFloat, placeholderColor: UIColor, sourceView: UIView?) {
    self.duration = duration
    self.curve = curve
    self.maskCornerRadius = maskCornerRadius
    self.overlayOpacity = overlayOpacity
    self.interactionScaleFactor = interactionScaleFactor
    self.placeholderColor = placeholderColor
    self.sourceView = sourceView
  }
}

extension ZoomTransitionConfig {
  public static var `default`: ZoomTransitionConfig {
    .init(
      duration: 0.35,
      curve: CAMediaTimingFunction(controlPoints: 0.5, 0, 0.6, 1),
      maskCornerRadius: UIScreen.main.displayCornerRadius,
      overlayOpacity: 0.5,
      interactionScaleFactor: 0.6,
      placeholderColor: .clear,
      sourceView: nil
    )
  }
  
//  public static var interactive: ZoomTransitionConfig {
//    .init(
//      duration: 2,
//      curve: CAMediaTimingFunction(controlPoints: 0.57, 0.27, 0.21, 0.97),
//      maskCornerRadius: 39,
//      overlayOpacity: 0.5,
//      interactionScaleFactor: 0.6,
//      placeholderColor: .blue
//    )
//  }
}
