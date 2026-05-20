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
  /// When `true` (default), a downward, primarily-vertical pan also drives interactive
  /// dismissal — in addition to the rightward-horizontal pan. Set to `false` to restrict
  /// dismissal to the horizontal axis only.
  var allowsVerticalPanDismissal: Bool

  public init(duration: TimeInterval,
              maskCornerRadius: CGFloat = CornerRadiusProvider.deviceCornerRadius,
              minimumScale: CGFloat = 0.5,
              maskVisualEffect: UIVisualEffect? = nil,
              dimmingColor: UIColor? = UIColor.black.withAlphaComponent(0.25),
              dimmingVisualEffect: UIBlurEffect? = nil,
              allowsVerticalPanDismissal: Bool = true) {
    self.duration = duration
    self.maskCornerRadius = maskCornerRadius
    self.minimumScale = minimumScale
    self.maskVisualEffect = maskVisualEffect
    self.dimmingColor = dimmingColor
    self.dimmingVisualEffect = dimmingVisualEffect
    self.allowsVerticalPanDismissal = allowsVerticalPanDismissal
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
