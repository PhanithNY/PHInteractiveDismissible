//
//  HomeServiceActionView.swift
//  Example
//
//  Created by Codex on 13/7/26.
//

import UIKit

final class HomeServiceActionView: UIControl {
  let service: HomeService
  let transitionSourceView = UIView()

  private let iconView = UIImageView()
  private let titleLabel = UILabel()

  init(service: HomeService, tintColor: UIColor) {
    self.service = service
    super.init(frame: .zero)
    prepareLayout(tintColor: tintColor)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.15) {
        self.transform = self.isHighlighted
          ? CGAffineTransform(scaleX: 0.94, y: 0.94)
          : .identity
        self.alpha = self.isHighlighted ? 0.82 : 1
      }
    }
  }

  private func prepareLayout(tintColor: UIColor) {
    isAccessibilityElement = true
    accessibilityLabel = service.title
    accessibilityHint = "Opens (service.title)"
    accessibilityTraits = .button

    transitionSourceView.backgroundColor = tintColor
    transitionSourceView.layer.cornerRadius = 24
    transitionSourceView.layer.cornerCurve = .continuous
    transitionSourceView.isUserInteractionEnabled = false

    iconView.image = UIImage(systemName: service.symbolName)
    iconView.tintColor = .white
    iconView.contentMode = .scaleAspectFit
    iconView.preferredSymbolConfiguration = .init(pointSize: 20, weight: .medium)

    titleLabel.text = service.title
    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .label
    titleLabel.textAlignment = .center
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.minimumScaleFactor = 0.72

    [transitionSourceView, titleLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }
    iconView.translatesAutoresizingMaskIntoConstraints = false
    transitionSourceView.addSubview(iconView)

    NSLayoutConstraint.activate([
      transitionSourceView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
      transitionSourceView.centerXAnchor.constraint(equalTo: centerXAnchor),
      transitionSourceView.widthAnchor.constraint(equalToConstant: 48),
      transitionSourceView.heightAnchor.constraint(equalToConstant: 48),

      iconView.centerXAnchor.constraint(equalTo: transitionSourceView.centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: transitionSourceView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 25),
      iconView.heightAnchor.constraint(equalToConstant: 25),

      titleLabel.topAnchor.constraint(equalTo: transitionSourceView.bottomAnchor, constant: 7),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
      titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
    ])
  }
}
