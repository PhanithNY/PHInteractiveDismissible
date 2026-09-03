//
//  ExampleTheme.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

enum ExampleTheme {
  static let brandName = "Atlas Bank"

  static let accent = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.58, green: 0.82, blue: 0.36, alpha: 1)
      : UIColor(red: 0.39, green: 0.74, blue: 0.24, alpha: 1)
  }

  static let pageBackground = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
      : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
  }

  static let cardBackground = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1)
      : .systemBackground
  }

  static let elevatedBackground = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1)
      : .systemBackground
  }

  static let subtleAccentBackground = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? accent.withAlphaComponent(0.18)
      : accent.withAlphaComponent(0.12)
  }

  static let shadowColor = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor.black.withAlphaComponent(0.45)
      : UIColor.black.withAlphaComponent(0.16)
  }

  static let cardGradientDark = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1)
      : UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1)
  }

  static let cardGradientBlue = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.16, green: 0.28, blue: 0.54, alpha: 1)
      : UIColor(red: 0.18, green: 0.32, blue: 0.62, alpha: 1)
  }

  static func applyNavigationAppearance() {
    let navigationAppearance = UINavigationBarAppearance()
    navigationAppearance.configureWithTransparentBackground()
    navigationAppearance.backgroundColor = .clear
    navigationAppearance.shadowColor = .clear
    UINavigationBar.appearance().standardAppearance = navigationAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
    UINavigationBar.appearance().compactAppearance = navigationAppearance

    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithDefaultBackground()
    tabBarAppearance.backgroundColor = cardBackground.withAlphaComponent(0.92)
    UITabBar.appearance().standardAppearance = tabBarAppearance
    if #available(iOS 15.0, *) {
      UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    UITabBar.appearance().tintColor = accent
  }
}
