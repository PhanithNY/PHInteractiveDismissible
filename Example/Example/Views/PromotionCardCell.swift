//
//  PromotionCardCell.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

final class PromotionCardCell: UICollectionViewCell {
  static let reuseIdentifier = "PromotionCardCell"

  let cardView = PromotionCardView()

  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    prepareLayout()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    prepareLayout()
  }

  func bind(_ promotion: Promotion) {
    cardView.bind(promotion)
    titleLabel.text = promotion.title
  }

  private func prepareLayout() {
    contentView.backgroundColor = .clear

    cardView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .subheadline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 2
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .left

    contentView.addSubview(cardView)
    contentView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
      cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.78),

      titleLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 10),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
    ])
  }
}

final class PromotionCardView: UIView {
  private let gradientLayer = CAGradientLayer()
  private let glossLayer = CAGradientLayer()
  private let iconView = UIImageView()
  private let badgeLabel = UILabel()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    prepareLayout()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    prepareLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
    gradientLayer.cornerRadius = layer.cornerRadius
    glossLayer.frame = bounds
    glossLayer.cornerRadius = layer.cornerRadius
  }

  func bind(_ promotion: Promotion) {
    gradientLayer.colors = promotion.colors.map(\.cgColor)
    iconView.image = UIImage(systemName: promotion.symbolName)
    titleLabel.text = promotion.title
    subtitleLabel.text = "Limited time"
    badgeLabel.text = "View offer"
  }

  private func prepareLayout() {
    layer.cornerRadius = 24
    layer.cornerCurve = .continuous
    layer.masksToBounds = true

    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    layer.insertSublayer(gradientLayer, at: 0)

    glossLayer.colors = [
      UIColor.white.withAlphaComponent(0.34).cgColor,
      UIColor.white.withAlphaComponent(0.04).cgColor,
      UIColor.black.withAlphaComponent(0.12).cgColor
    ]
    glossLayer.locations = [0, 0.42, 1]
    glossLayer.startPoint = CGPoint(x: 0, y: 0)
    glossLayer.endPoint = CGPoint(x: 1, y: 1)
    layer.insertSublayer(glossLayer, above: gradientLayer)

    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    iconView.tintColor = .white
    iconView.preferredSymbolConfiguration = .init(pointSize: 30, weight: .semibold)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .white
    titleLabel.numberOfLines = 2
    titleLabel.adjustsFontForContentSizeCategory = true

    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)
    subtitleLabel.numberOfLines = 2
    subtitleLabel.adjustsFontForContentSizeCategory = true

    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    badgeLabel.font = .preferredFont(forTextStyle: .caption2)
    badgeLabel.textColor = .white
    badgeLabel.numberOfLines = 1
    badgeLabel.textAlignment = .center
    badgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.20)
    badgeLabel.layer.cornerRadius = 12
    badgeLabel.layer.masksToBounds = true

    addSubview(titleLabel)
    addSubview(subtitleLabel)
    addSubview(iconView)
    addSubview(badgeLabel)

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),

      subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

      iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
      iconView.widthAnchor.constraint(equalToConstant: 44),
      iconView.heightAnchor.constraint(equalToConstant: 44),

      badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      badgeLabel.widthAnchor.constraint(equalToConstant: 82),
      badgeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      badgeLabel.heightAnchor.constraint(equalToConstant: 24)
    ])
  }
}
