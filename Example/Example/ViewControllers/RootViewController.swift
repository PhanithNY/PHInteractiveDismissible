//
//  RootViewController.swift
//  Example
//
//  Created by Phanith Ny on 8/12/25.
//

import PHInteractiveDismissible
import UIKit

final class RootViewController: UIViewController {
  private let promotions = Promotion.samples
  private let favorites = FavoriteItem.samples
  private var currentPromotionIndex = 0
  private var currentFavoriteIndex = 0
  private var favoriteTiles: [FavoriteTileView] = []
  private weak var selectedPromotionCard: PromotionCardView?
  private weak var selectedFavoriteTile: FavoriteTileView?
  private weak var favoritesScrollView: UIScrollView?
  private let brandGreen = ExampleTheme.accent
  private let pageBackground = ExampleTheme.pageBackground

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let stackView = UIStackView()
  private let topContentStackView = UIStackView()
  private var topBarHeightConstraint: NSLayoutConstraint?
  private var balanceCardHeightConstraint: NSLayoutConstraint?
  private var whatsNewHeightConstraint: NSLayoutConstraint?
  private var favoritesHeightConstraint: NSLayoutConstraint?
  private var stackTopConstraint: NSLayoutConstraint?
  private var stackBottomConstraint: NSLayoutConstraint?
  private var appliedLandscapeLayout: Bool?

  private lazy var whatsNewCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 18
    layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(PromotionCardCell.self,
                            forCellWithReuseIdentifier: PromotionCardCell.reuseIdentifier)
    return collectionView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    applyLayoutMetricsForCurrentSize()
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate { [weak self] _ in
      self?.applyLayoutMetricsForCurrentSize(size)
      self?.whatsNewCollectionView.collectionViewLayout.invalidateLayout()
    }
  }

  private func prepareLayout() {
    title = "Home"
    view.backgroundColor = pageBackground
    navigationController?.navigationBar.prefersLargeTitles = false
    navigationController?.navigationBar.shadowImage = UIImage()
    navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false

    stackView.axis = .vertical
    stackView.spacing = 24
    topContentStackView.axis = .vertical
    topContentStackView.spacing = 24

    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(stackView)

    stackTopConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
    stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      stackTopConstraint!,
      stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      stackBottomConstraint!
    ])

    stackView.addArrangedSubview(makeTopBar())
    topContentStackView.addArrangedSubview(makeBalanceCard())
    topContentStackView.addArrangedSubview(makeQuickActions())
    stackView.addArrangedSubview(topContentStackView)
    stackView.addArrangedSubview(makeWhatsNewSection())
    stackView.addArrangedSubview(makeFavoritesSection())
  }

  private func applyLayoutMetricsForCurrentSize(_ size: CGSize? = nil) {
    let targetSize = size ?? view.bounds.size
    let isLandscape = targetSize.width > targetSize.height
    guard appliedLandscapeLayout != isLandscape else { return }
    appliedLandscapeLayout = isLandscape

    stackView.spacing = isLandscape ? 12 : 24
    stackTopConstraint?.constant = isLandscape ? 12 : 24
    stackBottomConstraint?.constant = isLandscape ? -24 : -40
    topContentStackView.axis = isLandscape ? .horizontal : .vertical
    topContentStackView.spacing = isLandscape ? 12 : 24
    topContentStackView.distribution = isLandscape ? .fillEqually : .fill
    topBarHeightConstraint?.constant = isLandscape ? 48 : 64
    balanceCardHeightConstraint?.constant = isLandscape ? 118 : 154
    whatsNewHeightConstraint?.constant = isLandscape ? 232 : 286
    favoritesHeightConstraint?.constant = isLandscape ? 180 : 196
    whatsNewCollectionView.collectionViewLayout.invalidateLayout()
  }

  private func makeTopBar() -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false

    let rewardsButton = makePillButton(title: "Rewards", imageName: "gift.fill")
    rewardsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    let favoriteButton = makeIconPill(imageName: "heart")
    let notificationButton = makeIconPill(imageName: "bell")
    let chatButton = makeRoundButton(imageName: "message.badge", color: .systemRed)
    let actionStack = UIStackView(arrangedSubviews: [favoriteButton, notificationButton, chatButton])
    actionStack.axis = .horizontal
    actionStack.alignment = .center
    actionStack.spacing = 10
    actionStack.distribution = .fill

    [rewardsButton, actionStack].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview($0)
    }
    [favoriteButton, notificationButton, chatButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }

    topBarHeightConstraint = container.heightAnchor.constraint(equalToConstant: 64)

    NSLayoutConstraint.activate([
      topBarHeightConstraint!,

      rewardsButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      rewardsButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      rewardsButton.heightAnchor.constraint(equalToConstant: 52),

      actionStack.leadingAnchor.constraint(greaterThanOrEqualTo: rewardsButton.trailingAnchor, constant: 12),
      actionStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      actionStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      favoriteButton.widthAnchor.constraint(equalToConstant: 52),
      favoriteButton.heightAnchor.constraint(equalToConstant: 52),

      notificationButton.widthAnchor.constraint(equalToConstant: 52),
      notificationButton.heightAnchor.constraint(equalToConstant: 52),

      chatButton.widthAnchor.constraint(equalToConstant: 52),
      chatButton.heightAnchor.constraint(equalToConstant: 52)
    ])

    return container
  }

  private func makeBalanceCard() -> UIView {
    let card = UIView()
    card.translatesAutoresizingMaskIntoConstraints = false
    card.backgroundColor = ExampleTheme.cardBackground
    card.layer.cornerRadius = 26
    card.layer.cornerCurve = .continuous
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.07
    card.layer.shadowRadius = 18
    card.layer.shadowOffset = CGSize(width: 0, height: 8)

    let label = UILabel()
    label.text = "Total Balance"
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel

    let amountLabel = UILabel()
    amountLabel.text = "$ 12,840.25"
    amountLabel.font = .systemFont(ofSize: 32, weight: .bold)
    amountLabel.textColor = .label
    amountLabel.adjustsFontSizeToFitWidth = true
    amountLabel.minimumScaleFactor = 0.7

    let accountLabel = UILabel()
    accountLabel.text = "Savings •••• 8821"
    accountLabel.font = .preferredFont(forTextStyle: .footnote)
    accountLabel.textColor = .secondaryLabel

    let addButton = makeRoundButton(imageName: "plus", color: brandGreen)
    addButton.layer.cornerRadius = 21
    let transferButton = makePillButton(title: "Transfer", imageName: "arrow.left.arrow.right")
    transferButton.backgroundColor = ExampleTheme.subtleAccentBackground
    transferButton.tintColor = brandGreen
    transferButton.setTitleColor(brandGreen, for: .normal)
    transferButton.layer.cornerRadius = 19

    [label, amountLabel, accountLabel, addButton, transferButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview($0)
    }

    balanceCardHeightConstraint = card.heightAnchor.constraint(equalToConstant: 154)

    NSLayoutConstraint.activate([
      balanceCardHeightConstraint!,

      label.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
      label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),

      addButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
      addButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      addButton.widthAnchor.constraint(equalToConstant: 42),
      addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor),

      amountLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
      amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      amountLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

      accountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      accountLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),

      transferButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      transferButton.centerYAnchor.constraint(equalTo: accountLabel.centerYAnchor),
      transferButton.widthAnchor.constraint(equalToConstant: 116),
      transferButton.heightAnchor.constraint(equalToConstant: 38)
    ])

    let wrapper = UIView()
    wrapper.addSubview(card)
    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: wrapper.topAnchor),
      card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
      card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
      card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
    ])
    return wrapper
  }

  private func makeQuickActions() -> UIView {
    let container = UIStackView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.axis = .vertical
    container.spacing = 16

    container.addArrangedSubview(makeSegmentRow([
      "Account", "Top-Up", "Pay Bills", "Transfer"
    ]))

    container.addArrangedSubview(makeHorizontalActionRow([
      (makeSquareAction(imageName: "square.grid.2x2.fill"), 64),
      (makePillButton(title: "Loan", imageName: "dollarsign.circle"), 116),
      (makePillButton(title: "Cards", imageName: "creditcard"), 118),
      (makePillButton(title: "New Account", imageName: "plus.rectangle.on.folder"), 162)
    ], height: 58))

    return container
  }

  private func makeSegmentRow(_ titles: [String]) -> UIView {
    let wrapper = UIView()
    let row = UIStackView()
    row.axis = .horizontal
    row.distribution = .fillEqually
    row.spacing = 0
    row.backgroundColor = ExampleTheme.cardBackground
    row.layer.cornerRadius = 24
    row.layer.cornerCurve = .continuous
    row.translatesAutoresizingMaskIntoConstraints = false

    titles.forEach { title in
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.setTitleColor(.label, for: .normal)
      button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
      button.titleLabel?.adjustsFontSizeToFitWidth = true
      button.titleLabel?.minimumScaleFactor = 0.78
      row.addArrangedSubview(button)
    }

    wrapper.addSubview(row)

    NSLayoutConstraint.activate([
      wrapper.heightAnchor.constraint(equalToConstant: 52),
      row.topAnchor.constraint(equalTo: wrapper.topAnchor),
      row.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
      row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
      row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
    ])

    return wrapper
  }

  private func makeHorizontalActionRow(_ actions: [(UIButton, CGFloat)], height: CGFloat) -> UIView {
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.translatesAutoresizingMaskIntoConstraints = false

    scrollView.addSubview(row)

    actions.forEach { button, width in
      row.addArrangedSubview(button)
      button.widthAnchor.constraint(equalToConstant: width).isActive = true
      button.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    NSLayoutConstraint.activate([
      scrollView.heightAnchor.constraint(equalToConstant: height),

      row.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      row.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
      row.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
      row.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      row.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
    ])

    return scrollView
  }

  private func makeWhatsNewSection() -> UIView {
    let container = UIView()
    let titleLabel = makeSectionTitle("What’s New")
    let subtitleLabel = UILabel()
    subtitleLabel.text = "Fresh offers and rewards picked for your account."
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 2
    subtitleLabel.adjustsFontForContentSizeCategory = true
    whatsNewCollectionView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(titleLabel)
    container.addSubview(subtitleLabel)
    container.addSubview(whatsNewCollectionView)

    whatsNewHeightConstraint = container.heightAnchor.constraint(equalToConstant: 286)

    NSLayoutConstraint.activate([
      whatsNewHeightConstraint!,

      titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

      whatsNewCollectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
      whatsNewCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      whatsNewCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      whatsNewCollectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])

    return container
  }

  private func makeFavoritesSection() -> UIView {
    let container = UIView()
    let titleLabel = makeSectionTitle("Favorites")
    let actionButton = UIButton(type: .system)
    actionButton.setTitle("View All", for: .normal)
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    actionButton.tintColor = brandGreen

    let horizontalScrollView = UIScrollView()
    horizontalScrollView.showsHorizontalScrollIndicator = false
    favoritesScrollView = horizontalScrollView

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 16
    row.translatesAutoresizingMaskIntoConstraints = false

    favoriteTiles.removeAll()
    favorites.enumerated().forEach { index, favorite in
      let tile = FavoriteTileView()
      tile.bind(favorite)
      tile.tag = index
      tile.addTarget(self, action: #selector(didTapFavorite(_:)), for: .touchUpInside)
      row.addArrangedSubview(tile)
      favoriteTiles.append(tile)
      tile.widthAnchor.constraint(equalToConstant: 164).isActive = true
      tile.heightAnchor.constraint(equalToConstant: 132).isActive = true
    }

    horizontalScrollView.addSubview(row)

    [titleLabel, actionButton, horizontalScrollView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview($0)
    }

    favoritesHeightConstraint = container.heightAnchor.constraint(equalToConstant: 196)

    NSLayoutConstraint.activate([
      favoritesHeightConstraint!,

      titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

      actionButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      actionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

      horizontalScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
      horizontalScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      horizontalScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      horizontalScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

      row.topAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.topAnchor),
      row.leadingAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
      row.trailingAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
      row.bottomAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.bottomAnchor),
      row.heightAnchor.constraint(equalTo: horizontalScrollView.frameLayoutGuide.heightAnchor)
    ])

    return container
  }

  @objc
  private func didTapFavorite(_ sender: FavoriteTileView) {
    guard favorites.indices.contains(sender.tag) else { return }
    currentFavoriteIndex = sender.tag
    selectedFavoriteTile = sender

    let detailViewController = FavoriteDetailViewController(favorites: favorites, initialIndex: sender.tag) { [weak self] newIndex in
      self?.currentFavoriteIndex = newIndex
      self?.scrollFavoritesToItem(at: newIndex, animated: true)
      self?.selectedFavoriteTile = self?.favoriteTile(at: newIndex)
    }
    let navigationController = UINavigationController(rootViewController: detailViewController)

    zoom(to: navigationController, sourceViewProvider: { [weak self] in
      self?.sourceViewForCurrentFavorite()
    })
  }

  private func sourceViewForCurrentFavorite() -> UIView? {
    selectedFavoriteTile ?? favoriteTile(at: currentFavoriteIndex)
  }

  private func scrollFavoritesToItem(at index: Int, animated: Bool) {
    guard let favoritesScrollView,
          let tile = favoriteTile(at: index) else {
      return
    }

    let targetRect = tile.convert(tile.bounds, to: favoritesScrollView)
      .insetBy(dx: -20, dy: 0)
    favoritesScrollView.scrollRectToVisible(targetRect, animated: animated)
  }

  private func favoriteTile(at index: Int) -> FavoriteTileView? {
    guard favoriteTiles.indices.contains(index) else { return nil }
    return favoriteTiles[index]
  }

  private func makeServiceTile(title: String, imageName: String, color: UIColor) -> UIView {
    let tile = UIView()
    tile.backgroundColor = ExampleTheme.cardBackground
    tile.layer.cornerRadius = 22
    tile.layer.cornerCurve = .continuous
    tile.layer.shadowColor = UIColor.black.cgColor
    tile.layer.shadowOpacity = 0.05
    tile.layer.shadowRadius = 10
    tile.layer.shadowOffset = CGSize(width: 0, height: 4)

    let iconView = UIImageView(image: UIImage(systemName: imageName))
    iconView.tintColor = color
    iconView.contentMode = .scaleAspectFit
    iconView.preferredSymbolConfiguration = .init(pointSize: 36, weight: .semibold)

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .headline)
    label.adjustsFontForContentSizeCategory = true
    label.textAlignment = .center
    label.numberOfLines = 2

    [iconView, label].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      tile.addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.topAnchor.constraint(equalTo: tile.topAnchor, constant: 20),
      iconView.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 52),
      iconView.heightAnchor.constraint(equalToConstant: 52),

      label.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 8),
      label.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -8),
      label.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -18)
    ])

    return tile
  }

  private func makePillButton(title: String, imageName: String? = nil) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.setImage(imageName.flatMap(UIImage.init(systemName:)), for: .normal)
    button.backgroundColor = ExampleTheme.cardBackground
    button.tintColor = .label
    button.setTitleColor(.label, for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
    button.titleLabel?.adjustsFontSizeToFitWidth = true
    button.titleLabel?.minimumScaleFactor = 0.78
    button.layer.cornerRadius = 26
    button.layer.cornerCurve = .continuous
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = 0.04
    button.layer.shadowRadius = 8
    button.layer.shadowOffset = CGSize(width: 0, height: 3)
    button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
    return button
  }

  private func makeIconPill(imageName: String) -> UIButton {
    let button = makePillButton(title: "", imageName: imageName)
    button.contentEdgeInsets = .zero
    button.imageEdgeInsets = .zero
    button.titleEdgeInsets = .zero
    return button
  }

  private func makeRoundButton(imageName: String, color: UIColor) -> UIButton {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: imageName), for: .normal)
    button.backgroundColor = color
    button.tintColor = .white
    button.layer.cornerRadius = 26
    button.layer.cornerCurve = .continuous
    return button
  }

  private func makeSquareAction(imageName: String) -> UIButton {
    let button = makeRoundButton(imageName: imageName, color: ExampleTheme.cardBackground)
    button.tintColor = .label
    return button
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .title2)
    label.font = .systemFont(ofSize: 24, weight: .bold)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .label
    return label
  }

  private func openPromotion(at index: Int) {
    currentPromotionIndex = index
    selectedPromotionCard = (whatsNewCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? PromotionCardCell)?.cardView
    let pager = PromotionsPagerViewController(promotions: promotions, initialIndex: index) { [weak self] newIndex in
      self?.currentPromotionIndex = newIndex
      self?.scrollWhatsNewToPromotion(at: newIndex, animated: false)
      self?.selectedPromotionCard = (self?.whatsNewCollectionView.cellForItem(at: IndexPath(item: newIndex, section: 0)) as? PromotionCardCell)?.cardView
    }
    let navigationController = UINavigationController(rootViewController: pager)

    zoom(to: navigationController, sourceViewProvider: { [weak self] in
      self?.sourceViewForCurrentPromotion()
    })
  }

  private func sourceViewForCurrentPromotion() -> UIView? {
    view.layoutIfNeeded()
    whatsNewCollectionView.layoutIfNeeded()

    let indexPath = IndexPath(item: currentPromotionIndex, section: 0)
    return (whatsNewCollectionView.cellForItem(at: indexPath) as? PromotionCardCell)?.cardView
      ?? selectedPromotionCard
  }

  private func scrollWhatsNewToPromotion(at index: Int, animated: Bool) {
    guard promotions.indices.contains(index) else { return }
    whatsNewCollectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                        at: .centeredHorizontally,
                                        animated: animated)
  }
}

extension RootViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    promotions.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PromotionCardCell.reuseIdentifier,
                                                  for: indexPath) as! PromotionCardCell
    cell.bind(promotions[indexPath.item])
    return cell
  }
}

extension RootViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    openPromotion(at: indexPath.item)
  }
}

extension RootViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let isLandscape = view.bounds.width > view.bounds.height
    let width = isLandscape ? min(168, collectionView.bounds.width * 0.23) : min(220, collectionView.bounds.width * 0.38)
    return CGSize(width: max(148, width), height: isLandscape ? 146 : 196)
  }
}
