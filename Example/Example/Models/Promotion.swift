//
//  Promotion.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

struct Promotion: Hashable {
  let id: UUID = .init()
  let title: String
  let subtitle: String
  let symbolName: String
  let colors: [UIColor]

  static let samples: [Promotion] = [
    .init(title: "Exchange Rates",
          subtitle: "Check live foreign exchange before you transfer.",
          symbolName: "dollarsign.arrow.circlepath",
          colors: [.systemYellow, .systemGreen]),
    .init(title: "30% Cashback",
          subtitle: "Spend with Atlas Virtual Card and get rewarded.",
          symbolName: "creditcard.and.123",
          colors: [.systemBlue, .systemTeal]),
    .init(title: "Enjoy 30% OFF",
          subtitle: "Save more with selected Visa card partners.",
          symbolName: "creditcard.trianglebadge.exclamationmark",
          colors: [.systemIndigo, .systemYellow]),
    .init(title: "Custom Card",
          subtitle: "Pick a card style that matches your day.",
          symbolName: "person.crop.rectangle.stack",
          colors: [.systemRed, .systemPurple]),
    .init(title: "Travel Deals",
          subtitle: "Book flights and hotels with exclusive rates.",
          symbolName: "airplane.departure",
          colors: [UIColor(red: 0.0, green: 0.68, blue: 0.86, alpha: 1.0), .systemOrange]),
    .init(title: "Bill Rewards",
          subtitle: "Pay utilities and collect monthly bonus points.",
          symbolName: "doc.text.magnifyingglass",
          colors: [UIColor(red: 0.0, green: 0.72, blue: 0.58, alpha: 1.0), .systemBlue]),
    .init(title: "Partner Offers",
          subtitle: "Discover discounts from nearby merchants.",
          symbolName: "storefront",
          colors: [.systemPink, .systemOrange]),
    .init(title: "Weekend Boost",
          subtitle: "Extra cashback every Saturday and Sunday.",
          symbolName: "sparkles",
          colors: [.systemPurple, .systemBlue])
  ]
}
