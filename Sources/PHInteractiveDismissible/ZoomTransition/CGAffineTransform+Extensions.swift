//
//  CGAffineTransform+Extensions.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

extension CGAffineTransform {
  static func transform(parent: CGRect, soChild child: CGRect, aspectFills rect: CGRect) -> (transform: CGAffineTransform, scaleFactor: CGFloat) {
    let baseRect = child.isEmpty ? parent : child
    let scaleX = rect.width / baseRect.width
    let scaleY = rect.height / baseRect.height
    let scaleFactor = max(scaleX, scaleY)

    let translateX = rect.midX - baseRect.midX
    let translateY = rect.midY - baseRect.midY

    let transform = CGAffineTransform(
      a: scaleFactor,
      b: 0,
      c: 0,
      d: scaleFactor,
      tx: translateX,
      ty: translateY
    )
    return (transform: transform, scaleFactor: scaleFactor)
  }

}
