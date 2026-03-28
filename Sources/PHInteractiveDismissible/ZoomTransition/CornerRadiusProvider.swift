//
//  CornerRadiusProvider.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 25/12/25.
//

import UIKit
import PHInteractiveDismissibleObjC

public enum CornerRadiusProvider {
  public static var deviceCornerRadius: CGFloat {
    UIScreen.main.deviceCornerRadius
  }
}

extension UIScreen {
  fileprivate var deviceCornerRadius: CGFloat {
    CGFloat(truncating: PrivateCornerRadiusReader.displayCornerRadius(for: self) ?? 0)
  }
}
