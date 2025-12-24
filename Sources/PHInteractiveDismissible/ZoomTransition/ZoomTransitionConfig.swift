//
//  ZoomTransitionConfig.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public struct ZoomTransitionConfig {
  var duration: CGFloat
  var maskCornerRadius: CGFloat
  var overlayOpacity: Float
  var interactionScaleFactor: CGFloat = .zero
  var placeholderColor: UIColor
  var sourceView: UIView?
  
  public init(duration: CGFloat, maskCornerRadius: CGFloat, overlayOpacity: Float, interactionScaleFactor: CGFloat, placeholderColor: UIColor, sourceView: UIView?) {
    self.duration = duration
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
      maskCornerRadius: UIScreen.main.displayCornerRadius,
      overlayOpacity: 0.5,
      interactionScaleFactor: 0.6,
      placeholderColor: .clear,
      sourceView: nil
    )
  }
}
