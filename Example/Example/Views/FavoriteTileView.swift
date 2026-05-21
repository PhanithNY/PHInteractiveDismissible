//
//  FavoriteTileView.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

final class FavoriteTileView: UIControl {
  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let amountLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    prepareLayout()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    prepareLayout()
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.18) {
        self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        self.alpha = self.isHighlighted ? 0.82 : 1.0
      }
    }
  }

  func bind(_ item: FavoriteItem) {
    iconView.image = UIImage(systemName: item.symbolName)
    iconView.tintColor = item.color
    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
    amountLabel.text = item.amount
  }

  private func prepareLayout() {
    backgroundColor = ExampleTheme.cardBackground
    layer.cornerRadius = 22
    layer.cornerCurve = .continuous
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.06
    layer.shadowRadius = 12
    layer.shadowOffset = CGSize(width: 0, height: 5)

    iconView.contentMode = .scaleAspectFit
    iconView.preferredSymbolConfiguration = .init(pointSize: 34, weight: .semibold)

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.adjustsFontForContentSizeCategory = true

    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.adjustsFontForContentSizeCategory = true

    amountLabel.font = .preferredFont(forTextStyle: .subheadline)
    amountLabel.textColor = .label
    amountLabel.adjustsFontForContentSizeCategory = true

    [iconView, titleLabel, subtitleLabel, amountLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      iconView.widthAnchor.constraint(equalToConstant: 42),
      iconView.heightAnchor.constraint(equalToConstant: 42),

      amountLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
      amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 14),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
    ])
  }
}
