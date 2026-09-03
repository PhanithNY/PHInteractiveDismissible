//
//  FavoriteItem.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

struct FavoriteItem {
  let title: String
  let subtitle: String
  let amount: String
  let symbolName: String
  let color: UIColor

  static let samples: [FavoriteItem] = [
    .init(title: "CSX", subtitle: "Securities", amount: "$1,240", symbolName: "chart.line.uptrend.xyaxis.circle.fill", color: .systemIndigo),
    .init(title: "KHR", subtitle: "Local transfer", amount: "៛840K", symbolName: "arrow.triangle.2.circlepath.circle.fill", color: .systemGray),
    .init(title: "Capital", subtitle: "Bill payment", amount: "$72", symbolName: "receipt.circle.fill", color: .systemGreen),
    .init(title: "Sis", subtitle: "Family", amount: "$120", symbolName: "building.columns.circle.fill", color: .systemTeal),
    .init(title: "Ah Kberk", subtitle: "Merchant", amount: "$36", symbolName: "arrow.left.arrow.right.circle.fill", color: .systemOrange)
  ]
}
