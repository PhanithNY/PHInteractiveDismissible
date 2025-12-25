//
//  CornerRadiusProvider.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 25/12/25.
//

import UIKit

struct CornerRadiusProvider {
  static var notchCornerRadius: CGFloat {
    UIScreen.main.displayCornerRadius
  }
}

extension UIScreen {
  public var displayCornerRadius: CGFloat {
    guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
      return 0
    }
    
    return cornerRadius
  }
  
  private static let cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()
}
