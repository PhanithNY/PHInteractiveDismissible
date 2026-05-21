//
//  MoreViewController.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import UIKit

final class MoreViewController: UIViewController {
  private let pageBackground = ExampleTheme.pageBackground
  private let brandGreen = ExampleTheme.accent
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
  }

  private func prepareLayout() {
    title = "More"
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

    stackView.addArrangedSubview(makeProfileHeader())
    stackView.addArrangedSubview(makeShortcutGrid())
    stackView.addArrangedSubview(makeSection(title: "Banking", rows: [
      ("Scheduled payments", "calendar.badge.clock"),
      ("Recipients", "person.2.fill"),
      ("Exchange rates", "chart.line.uptrend.xyaxis"),
      ("Documents", "doc.text.fill")
    ]))
    stackView.addArrangedSubview(makeSection(title: "Support", rows: [
      ("Help center", "questionmark.circle.fill"),
      ("Security settings", "lock.shield.fill"),
      ("Contact Atlas", "bubble.left.and.bubble.right.fill")
    ]))
  }

  private func makeProfileHeader() -> UIView {
    let card = UIView()
    card.backgroundColor = ExampleTheme.cardBackground
    card.layer.cornerRadius = 24
    card.layer.cornerCurve = .continuous

    let avatar = UIView()
    avatar.backgroundColor = brandGreen
    avatar.layer.cornerRadius = 28
    avatar.layer.cornerCurve = .continuous

    let initials = UILabel()
    initials.text = "PN"
    initials.textColor = .white
    initials.font = .systemFont(ofSize: 18, weight: .bold)
    initials.textAlignment = .center

    let nameLabel = label("Phanith Ny", style: .headline, color: .label)
    let subtitleLabel = label("\(ExampleTheme.brandName) Premier", style: .subheadline, color: .secondaryLabel)
    let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    chevron.tintColor = .tertiaryLabel

    [avatar, nameLabel, subtitleLabel, chevron].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview($0)
    }
    initials.translatesAutoresizingMaskIntoConstraints = false
    avatar.addSubview(initials)

    NSLayoutConstraint.activate([
      card.heightAnchor.constraint(equalToConstant: 92),
      avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
      avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),
      initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

      nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
      nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

      chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor)
    ])

    return card
  }

  private func makeShortcutGrid() -> UIView {
    let grid = UIStackView()
    grid.axis = .vertical
    grid.spacing = 12

    let firstRow = UIStackView()
    firstRow.axis = .horizontal
    firstRow.spacing = 12
    firstRow.distribution = .fillEqually

    let secondRow = UIStackView()
    secondRow.axis = .horizontal
    secondRow.spacing = 12
    secondRow.distribution = .fillEqually

    [
      ("QR Pay", "qrcode.viewfinder"),
      ("Top Up", "iphone.gen3"),
      ("Loans", "banknote"),
      ("Rewards", "gift.fill"),
      ("Locator", "mappin.and.ellipse"),
      ("Settings", "gearshape.fill")
    ].enumerated().forEach { index, item in
      let tile = makeShortcut(title: item.0, imageName: item.1)
      (index < 3 ? firstRow : secondRow).addArrangedSubview(tile)
    }

    grid.addArrangedSubview(firstRow)
    grid.addArrangedSubview(secondRow)
    return grid
  }

  private func makeShortcut(title: String, imageName: String) -> UIView {
    let tile = UIView()
    tile.backgroundColor = ExampleTheme.cardBackground
    tile.layer.cornerRadius = 20
    tile.layer.cornerCurve = .continuous

    let icon = UIImageView(image: UIImage(systemName: imageName))
    icon.tintColor = brandGreen
    icon.contentMode = .scaleAspectFit
    let titleLabel = label(title, style: .caption1, color: .label)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 1

    [icon, titleLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      tile.addSubview($0)
    }

    NSLayoutConstraint.activate([
      tile.heightAnchor.constraint(equalToConstant: 92),
      icon.topAnchor.constraint(equalTo: tile.topAnchor, constant: 18),
      icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
      icon.widthAnchor.constraint(equalToConstant: 30),
      icon.heightAnchor.constraint(equalToConstant: 30),
      titleLabel.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -8),
      titleLabel.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -16)
    ])

    return tile
  }

  private func makeSection(title: String, rows: [(String, String)]) -> UIView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10

    let titleLabel = label(title, style: .title3, color: .label, weight: .bold)
    container.addArrangedSubview(titleLabel)

    let list = UIStackView()
    list.axis = .vertical
    list.spacing = 1
    list.layer.cornerRadius = 20
    list.layer.cornerCurve = .continuous
    list.clipsToBounds = true
    rows.forEach { list.addArrangedSubview(makeRow(title: $0.0, imageName: $0.1)) }
    container.addArrangedSubview(list)
    return container
  }

  private func makeRow(title: String, imageName: String) -> UIView {
    let row = UIView()
    row.backgroundColor = ExampleTheme.cardBackground

    let icon = UIImageView(image: UIImage(systemName: imageName))
    icon.tintColor = brandGreen
    let titleLabel = label(title, style: .subheadline, color: .label)
    let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    chevron.tintColor = .tertiaryLabel

    [icon, titleLabel, chevron].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      row.heightAnchor.constraint(equalToConstant: 56),
      icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
      icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 24),
      icon.heightAnchor.constraint(equalToConstant: 24),
      titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
      titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
      chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
    ])

    return row
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
