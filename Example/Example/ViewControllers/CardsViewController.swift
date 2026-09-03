//
//  CardsViewController.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

final class CardsViewController: UIViewController {
  private let pageBackground = ExampleTheme.pageBackground
  private let brandGreen = ExampleTheme.accent
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
  }

  private func prepareLayout() {
    title = "Cards"
    view.backgroundColor = pageBackground

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 22
    stackView.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 36, right: 20)
    stackView.isLayoutMarginsRelativeArrangement = true

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
    ])

    stackView.addArrangedSubview(makeHeroCard())
    stackView.addArrangedSubview(makeCardActions())
    stackView.addArrangedSubview(makeSectionTitle("Recent Card Activity"))
    stackView.addArrangedSubview(makeActivityList())
    stackView.addArrangedSubview(makeSectionTitle("Card Controls"))
    stackView.addArrangedSubview(makeControlPanel())
  }

  private func makeHeroCard() -> UIView {
    let card = UIView()
    card.backgroundColor = .black
    card.layer.cornerRadius = 26
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true

    let gradient = CAGradientLayer()
    gradient.colors = [
      ExampleTheme.cardGradientDark.cgColor,
      ExampleTheme.cardGradientBlue.cgColor,
      brandGreen.cgColor
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    card.layer.insertSublayer(gradient, at: 0)

    let nameLabel = label("Atlas Visa Platinum", style: .headline, color: .white)
    let numberLabel = label("••••  ••••  ••••  6824", style: .title2, color: .white)
    let balanceLabel = label("Available limit", style: .caption1, color: UIColor.white.withAlphaComponent(0.72))
    let amountLabel = label("$ 4,200.00", style: .title1, color: .white)
    let chip = UIImageView(image: UIImage(systemName: "simcard.fill"))
    chip.tintColor = UIColor.white.withAlphaComponent(0.92)
    chip.contentMode = .scaleAspectFit

    [nameLabel, numberLabel, balanceLabel, amountLabel, chip].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview($0)
    }

    NSLayoutConstraint.activate([
      card.heightAnchor.constraint(equalToConstant: 210),

      nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),

      chip.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      chip.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
      chip.widthAnchor.constraint(equalToConstant: 42),
      chip.heightAnchor.constraint(equalToConstant: 42),

      numberLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
      numberLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
      numberLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 8),

      balanceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
      balanceLabel.bottomAnchor.constraint(equalTo: amountLabel.topAnchor, constant: -4),

      amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
      amountLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
    ])

    card.layoutIfNeeded()
    gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 210)
    return card
  }

  private func makeCardActions() -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.distribution = .fillEqually
    row.spacing = 12
    [
      ("Freeze", "snowflake"),
      ("Limit", "slider.horizontal.3"),
      ("PIN", "key.fill"),
      ("Details", "doc.text.fill")
    ].forEach {
      row.addArrangedSubview(makeActionTile(title: $0.0, imageName: $0.1))
    }
    return row
  }

  private func makeActivityList() -> UIView {
    let list = UIStackView()
    list.axis = .vertical
    list.spacing = 1
    list.layer.cornerRadius = 20
    list.layer.cornerCurve = .continuous
    list.clipsToBounds = true
    [
      ("Amazon Marketplace", "Today", "-$82.40"),
      ("Atlas Rewards", "Yesterday", "+$12.00"),
      ("Coffee Club", "May 20", "-$4.75")
    ].forEach {
      list.addArrangedSubview(makeActivityRow(title: $0.0, subtitle: $0.1, amount: $0.2))
    }
    return list
  }

  private func makeControlPanel() -> UIView {
    let panel = UIStackView()
    panel.axis = .vertical
    panel.spacing = 1
    panel.layer.cornerRadius = 20
    panel.layer.cornerCurve = .continuous
    panel.clipsToBounds = true
    [
      ("Online payments", "Enabled", "wifi"),
      ("International usage", "Disabled", "globe"),
      ("ATM withdrawals", "Enabled", "banknote")
    ].forEach {
      panel.addArrangedSubview(makeActivityRow(title: $0.0, subtitle: $0.1, amount: "", iconName: $0.2))
    }
    return panel
  }

  private func makeActionTile(title: String, imageName: String) -> UIView {
    let tile = UIView()
    tile.backgroundColor = ExampleTheme.cardBackground
    tile.layer.cornerRadius = 18
    tile.layer.cornerCurve = .continuous

    let icon = UIImageView(image: UIImage(systemName: imageName))
    icon.tintColor = brandGreen
    icon.contentMode = .scaleAspectFit
    let titleLabel = label(title, style: .caption1, color: .label)
    titleLabel.textAlignment = .center

    [icon, titleLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      tile.addSubview($0)
    }

    NSLayoutConstraint.activate([
      tile.heightAnchor.constraint(equalToConstant: 84),
      icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
      icon.topAnchor.constraint(equalTo: tile.topAnchor, constant: 16),
      icon.widthAnchor.constraint(equalToConstant: 28),
      icon.heightAnchor.constraint(equalToConstant: 28),
      titleLabel.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 6),
      titleLabel.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -6),
      titleLabel.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -14)
    ])

    return tile
  }

  private func makeActivityRow(title: String, subtitle: String, amount: String, iconName: String = "creditcard.fill") -> UIView {
    let row = UIView()
    row.backgroundColor = ExampleTheme.cardBackground
    let icon = UIImageView(image: UIImage(systemName: iconName))
    icon.tintColor = brandGreen
    icon.contentMode = .scaleAspectFit
    let titleLabel = label(title, style: .subheadline, color: .label)
    let subtitleLabel = label(subtitle, style: .caption1, color: .secondaryLabel)
    let amountLabel = label(amount, style: .subheadline, color: amount.hasPrefix("+") ? brandGreen : .label)
    amountLabel.textAlignment = .right

    [icon, titleLabel, subtitleLabel, amountLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      row.heightAnchor.constraint(equalToConstant: 64),
      icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
      icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 28),
      icon.heightAnchor.constraint(equalToConstant: 28),

      titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
      titleLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 13),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -12),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),

      amountLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
      amountLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      amountLabel.widthAnchor.constraint(equalToConstant: 88)
    ])

    return row
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    label(text, style: .title3, color: .label, weight: .bold)
  }

  private func label(_ text: String,
                     style: UIFont.TextStyle,
                     color: UIColor,
                     weight: UIFont.Weight? = nil) -> UILabel {
    let label = UILabel()
    label.text = text
    label.textColor = color
    label.font = weight.map { .systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: $0) }
      ?? .preferredFont(forTextStyle: style)
    label.adjustsFontForContentSizeCategory = true
    return label
  }
}
