//
//  HomeServiceDetailViewController.swift
//  Example
//
//  Created by Codex on 13/7/26.
//

import PHInteractiveDismissible
import UIKit

final class HomeServiceDetailViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {
  var dismissibleScrollView: UIScrollView? { scrollView }

  var interactiveDismissShouldBegin: (() -> Bool)? {
    { [weak self] in
      self?.navigationController?.viewControllers.count == 1
    }
  }

  var zoomOption: PHInteractiveDismissible.ZoomOptions? {
    .init(
      duration: 0.35,
      maskVisualEffect: UIBlurEffect(style: .systemThickMaterial),
      dimmingColor: UIColor.black.withAlphaComponent(0.14),
      dimmingVisualEffect: nil
    )
  }

  private let service: HomeService
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  init(service: HomeService) {
    self.service = service
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
  }

  private func prepareLayout() {
    title = service.title
    view.backgroundColor = ExampleTheme.pageBackground
    navigationItem.leftBarButtonItem = .init(
      image: UIImage(systemName: "chevron.down"),
      style: .plain,
      target: self,
      action: #selector(dismissSelf)
    )

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 20
    stackView.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 44, right: 20)
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

    stackView.addArrangedSubview(makeHero())
    stackView.addArrangedSubview(makeSectionTitle("Quick access"))
    stackView.addArrangedSubview(makeHighlightsCard())
    stackView.addArrangedSubview(makePrimaryButton())
  }

  private func makeHero() -> UIView {
    let hero = UIView()
    hero.backgroundColor = ExampleTheme.accent
    hero.layer.cornerRadius = 28
    hero.layer.cornerCurve = .continuous

    let iconCircle = UIView()
    iconCircle.backgroundColor = UIColor.white.withAlphaComponent(0.18)
    iconCircle.layer.cornerRadius = 38
    iconCircle.layer.cornerCurve = .continuous

    let iconView = UIImageView(image: UIImage(systemName: service.symbolName))
    iconView.tintColor = .white
    iconView.contentMode = .scaleAspectFit
    iconView.preferredSymbolConfiguration = .init(pointSize: 30, weight: .semibold)

    let titleLabel = UILabel()
    titleLabel.text = service.title
    titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
    titleLabel.textColor = .white
    titleLabel.adjustsFontForContentSizeCategory = true

    let subtitleLabel = UILabel()
    subtitleLabel.text = service.subtitle
    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
    subtitleLabel.numberOfLines = 0
    subtitleLabel.adjustsFontForContentSizeCategory = true

    [iconCircle, iconView, titleLabel, subtitleLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      hero.addSubview($0)
    }

    NSLayoutConstraint.activate([
      hero.heightAnchor.constraint(greaterThanOrEqualToConstant: 224),

      iconCircle.topAnchor.constraint(equalTo: hero.topAnchor, constant: 24),
      iconCircle.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
      iconCircle.widthAnchor.constraint(equalToConstant: 76),
      iconCircle.heightAnchor.constraint(equalToConstant: 76),

      iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 38),
      iconView.heightAnchor.constraint(equalToConstant: 38),

      titleLabel.topAnchor.constraint(equalTo: iconCircle.bottomAnchor, constant: 18),
      titleLabel.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
      titleLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -24),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: hero.bottomAnchor, constant: -24)
    ])

    return hero
  }

  private func makeHighlightsCard() -> UIView {
    let card = UIStackView()
    card.axis = .vertical
    card.spacing = 1 / UIScreen.main.scale
    card.backgroundColor = .separator
    card.layer.cornerRadius = 20
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true

    service.highlights.forEach { item in
      card.addArrangedSubview(makeHighlightRow(
        title: item.title,
        subtitle: item.subtitle,
        symbolName: item.symbolName
      ))
    }

    return card
  }

  private func makeHighlightRow(title: String,
                                subtitle: String,
                                symbolName: String) -> UIView {
    let row = UIView()
    row.backgroundColor = ExampleTheme.cardBackground

    let iconView = UIImageView(image: UIImage(systemName: symbolName))
    iconView.tintColor = ExampleTheme.accent
    iconView.contentMode = .scaleAspectFit
    iconView.preferredSymbolConfiguration = .init(pointSize: 19, weight: .medium)

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.adjustsFontForContentSizeCategory = true

    let subtitleLabel = UILabel()
    subtitleLabel.text = subtitle
    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.adjustsFontForContentSizeCategory = true

    [iconView, titleLabel, subtitleLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview($0)
    }

    NSLayoutConstraint.activate([
      row.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

      iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18),
      iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 30),
      iconView.heightAnchor.constraint(equalToConstant: 30),

      titleLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
      titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -12)
    ])

    return row
  }

  private func makePrimaryButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(service.actionTitle, for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    button.backgroundColor = ExampleTheme.accent
    button.layer.cornerRadius = 24
    button.layer.cornerCurve = .continuous
    button.heightAnchor.constraint(equalToConstant: 52).isActive = true
    return button
  }

  private func makeSectionTitle(_ title: String) -> UILabel {
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 20, weight: .bold)
    label.adjustsFontForContentSizeCategory = true
    return label
  }

  @objc
  private func dismissSelf() {
    dismiss(animated: true)
  }
}
