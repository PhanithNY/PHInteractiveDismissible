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

  private var heroHeightConstraint: NSLayoutConstraint?
  private var topBarHeightConstraint: NSLayoutConstraint?
  private var whatsNewHeightConstraint: NSLayoutConstraint?
  private var favoritesHeightConstraint: NSLayoutConstraint?
  private var appliedLandscapeLayout: Bool?

  private lazy var whatsNewCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 12
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

  override var preferredStatusBarStyle: UIStatusBarStyle {
    .darkContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    applyLayoutMetricsForCurrentSize()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate { [weak self] _ in
      self?.applyLayoutMetricsForCurrentSize(size)
      self?.whatsNewCollectionView.collectionViewLayout.invalidateLayout()
    }
  }

  private func prepareLayout() {
    title = nil
    view.backgroundColor = brandGreen

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.backgroundColor = brandGreen
    scrollView.alwaysBounceVertical = true
    scrollView.contentInsetAdjustmentBehavior = .never

    contentView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 0

    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(stackView)

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

      stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
    ])

    stackView.addArrangedSubview(makeHero())
    stackView.addArrangedSubview(makeContentSheet())
  }

  private func applyLayoutMetricsForCurrentSize(_ size: CGSize? = nil) {
    let targetSize = size ?? view.bounds.size
    let isLandscape = targetSize.width > targetSize.height
    guard appliedLandscapeLayout != isLandscape else { return }
    appliedLandscapeLayout = isLandscape

    heroHeightConstraint?.constant = isLandscape ? 170 : 246
    topBarHeightConstraint?.constant = isLandscape ? 48 : 52
    whatsNewHeightConstraint?.constant = isLandscape ? 164 : 184
    favoritesHeightConstraint?.constant = isLandscape ? 168 : 196
    whatsNewCollectionView.collectionViewLayout.invalidateLayout()
  }

  private func makeHero() -> UIView {
    let hero = UIView()
    hero.backgroundColor = brandGreen

    let messageLabel = UILabel()
    messageLabel.text = "Ny Phanith!\nEverything you need, right here."
    messageLabel.font = .systemFont(ofSize: 17, weight: .regular)
    messageLabel.textColor = UIColor.white.withAlphaComponent(0.94)
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 2
    messageLabel.adjustsFontForContentSizeCategory = true

    let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
    chevronView.tintColor = UIColor.white.withAlphaComponent(0.9)
    chevronView.contentMode = .scaleAspectFit
    chevronView.preferredSymbolConfiguration = .init(pointSize: 16, weight: .medium)

    [messageLabel, chevronView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      hero.addSubview($0)
    }

    heroHeightConstraint = hero.heightAnchor.constraint(equalToConstant: 246)

    NSLayoutConstraint.activate([
      heroHeightConstraint!,

      messageLabel.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 28),
      messageLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -28),
      messageLabel.centerYAnchor.constraint(equalTo: hero.centerYAnchor, constant: 8),

      chevronView.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
      chevronView.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -12),
      chevronView.widthAnchor.constraint(equalToConstant: 24),
      chevronView.heightAnchor.constraint(equalToConstant: 24)
    ])

    return hero
  }

  private func makeContentSheet() -> UIView {
    let sheet = UIView()
    sheet.backgroundColor = pageBackground
    sheet.layer.cornerRadius = 30
    sheet.layer.cornerCurve = .continuous
    sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    sheet.clipsToBounds = true

    let bodyStack = UIStackView()
    bodyStack.translatesAutoresizingMaskIntoConstraints = false
    bodyStack.axis = .vertical
    bodyStack.spacing = 18

    sheet.addSubview(bodyStack)

    NSLayoutConstraint.activate([
      bodyStack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 12),
      bodyStack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
      bodyStack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
      bodyStack.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -96)
    ])

    bodyStack.addArrangedSubview(makeTopBar())
    bodyStack.addArrangedSubview(makeServicesCard())
    bodyStack.addArrangedSubview(makeServiceChips())
    bodyStack.setCustomSpacing(28, after: bodyStack.arrangedSubviews.last!)
    bodyStack.addArrangedSubview(makeWhatsNewSection())
    bodyStack.addArrangedSubview(makeFavoritesSection())

    return sheet
  }

  private func makeTopBar() -> UIView {
    let container = UIView()

    let rewardsButton = makePillButton(title: "Rewards", imageName: "gift.fill")
    rewardsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    rewardsButton.accessibilityHint = "Open your rewards"

    let actionPill = makeHeaderActionPill()
    let chatButton = makeRoundButton(imageName: "message.fill", color: .systemRed)
    chatButton.accessibilityLabel = "Messages"

    [rewardsButton, actionPill, chatButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview($0)
    }

    topBarHeightConstraint = container.heightAnchor.constraint(equalToConstant: 52)

    NSLayoutConstraint.activate([
      topBarHeightConstraint!,

      rewardsButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      rewardsButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      rewardsButton.widthAnchor.constraint(equalToConstant: 112),
      rewardsButton.heightAnchor.constraint(equalToConstant: 44),

      chatButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      chatButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      chatButton.widthAnchor.constraint(equalToConstant: 44),
      chatButton.heightAnchor.constraint(equalToConstant: 44),

      actionPill.trailingAnchor.constraint(equalTo: chatButton.leadingAnchor, constant: -10),
      actionPill.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      actionPill.widthAnchor.constraint(equalToConstant: 104),
      actionPill.heightAnchor.constraint(equalToConstant: 44),

      actionPill.leadingAnchor.constraint(greaterThanOrEqualTo: rewardsButton.trailingAnchor, constant: 12)
    ])

    return container
  }

  private func makeHeaderActionPill() -> UIView {
    let pill = UIView()
    pill.backgroundColor = ExampleTheme.cardBackground
    pill.layer.cornerRadius = 22
    pill.layer.cornerCurve = .continuous

    let favoriteButton = UIButton(type: .system)
    favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
    favoriteButton.tintColor = .label
    favoriteButton.accessibilityLabel = "Favorites"

    let notificationButton = UIButton(type: .system)
    notificationButton.setImage(UIImage(systemName: "bell"), for: .normal)
    notificationButton.tintColor = .label
    notificationButton.accessibilityLabel = "Notifications"

    let row = UIStackView(arrangedSubviews: [favoriteButton, notificationButton])
    row.translatesAutoresizingMaskIntoConstraints = false
    row.axis = .horizontal
    row.distribution = .fillEqually

    pill.addSubview(row)
    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: pill.topAnchor),
      row.leadingAnchor.constraint(equalTo: pill.leadingAnchor),
      row.trailingAnchor.constraint(equalTo: pill.trailingAnchor),
      row.bottomAnchor.constraint(equalTo: pill.bottomAnchor)
    ])

    return pill
  }

  private func makeServicesCard() -> UIView {
    let wrapper = UIView()
    let card = UIView()
    card.translatesAutoresizingMaskIntoConstraints = false
    card.backgroundColor = ExampleTheme.cardBackground
    card.layer.cornerRadius = 18
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true

    let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    searchIcon.tintColor = .label
    searchIcon.contentMode = .scaleAspectFit
    searchIcon.preferredSymbolConfiguration = .init(pointSize: 20, weight: .regular)

    let placeholderLabel = UILabel()
    placeholderLabel.text = "Search services and offers"
    placeholderLabel.font = .preferredFont(forTextStyle: .subheadline)
    placeholderLabel.textColor = .secondaryLabel
    placeholderLabel.adjustsFontForContentSizeCategory = true

    let divider = UIView()
    divider.backgroundColor = .separator

    let actions = HomeService.allCases.map { service in
      let actionView = HomeServiceActionView(service: service, tintColor: brandGreen)
      actionView.addTarget(self, action: #selector(didTapService(_:)), for: .touchUpInside)
      return actionView
    }
    let actionsRow = UIStackView(arrangedSubviews: actions)
    actionsRow.axis = .horizontal
    actionsRow.distribution = .fillEqually
    actionsRow.alignment = .fill

    [searchIcon, placeholderLabel, divider, actionsRow].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview($0)
    }

    wrapper.addSubview(card)

    NSLayoutConstraint.activate([
      wrapper.heightAnchor.constraint(equalToConstant: 154),

      card.topAnchor.constraint(equalTo: wrapper.topAnchor),
      card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
      card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
      card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

      searchIcon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      searchIcon.centerYAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      searchIcon.widthAnchor.constraint(equalToConstant: 26),
      searchIcon.heightAnchor.constraint(equalToConstant: 26),

      placeholderLabel.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
      placeholderLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      placeholderLabel.centerYAnchor.constraint(equalTo: searchIcon.centerYAnchor),

      divider.topAnchor.constraint(equalTo: card.topAnchor, constant: 48),
      divider.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

      actionsRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
      actionsRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
      actionsRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
      actionsRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
    ])

    return wrapper
  }

  @objc
  private func didTapService(_ sender: HomeServiceActionView) {
    let detailViewController = HomeServiceDetailViewController(service: sender.service)
    let navigationController = UINavigationController(rootViewController: detailViewController)

    zoom(to: navigationController, sourceViewProvider: { [weak sender] in
      sender?.transitionSourceView
    })
  }

  private func makeServiceChips() -> UIView {
    makeHorizontalActionRow([
      (makeSquareAction(imageName: "square.grid.2x2.fill"), 48),
      (makePillButton(title: "Loans", imageName: "banknote"), 108),
      (makePillButton(title: "My Cards", imageName: "creditcard"), 132),
      (makePillButton(title: "Open Account", imageName: "plus.rectangle.on.folder"), 156)
    ], height: 44)
  }

  private func makeHorizontalActionRow(_ actions: [(UIButton, CGFloat)], height: CGFloat) -> UIView {
    let horizontalScrollView = UIScrollView()
    horizontalScrollView.showsHorizontalScrollIndicator = false

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 10
    row.translatesAutoresizingMaskIntoConstraints = false

    horizontalScrollView.addSubview(row)

    actions.forEach { button, width in
      button.layer.cornerRadius = 16
      row.addArrangedSubview(button)
      button.widthAnchor.constraint(equalToConstant: width).isActive = true
      button.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    NSLayoutConstraint.activate([
      horizontalScrollView.heightAnchor.constraint(equalToConstant: height),

      row.topAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.topAnchor),
      row.leadingAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
      row.trailingAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
      row.bottomAnchor.constraint(equalTo: horizontalScrollView.contentLayoutGuide.bottomAnchor),
      row.heightAnchor.constraint(equalTo: horizontalScrollView.frameLayoutGuide.heightAnchor)
    ])

    return horizontalScrollView
  }

  private func makeWhatsNewSection() -> UIView {
    let container = UIView()
    let titleLabel = makeSectionTitle("New for you")
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    whatsNewCollectionView.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(titleLabel)
    container.addSubview(whatsNewCollectionView)

    whatsNewHeightConstraint = container.heightAnchor.constraint(equalToConstant: 184)

    NSLayoutConstraint.activate([
      whatsNewHeightConstraint!,

      titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

      whatsNewCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      whatsNewCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      whatsNewCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      whatsNewCollectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])

    return container
  }

  private func makeFavoritesSection() -> UIView {
    let container = UIView()
    let titleLabel = makeSectionTitle("Popular services")
    let actionButton = UIButton(type: .system)
    actionButton.setTitle("View All", for: .normal)
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    actionButton.tintColor = brandGreen

    let horizontalScrollView = UIScrollView()
    horizontalScrollView.showsHorizontalScrollIndicator = false
    favoritesScrollView = horizontalScrollView

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 14
    row.translatesAutoresizingMaskIntoConstraints = false

    favoriteTiles.removeAll()
    favorites.enumerated().forEach { index, favorite in
      let tile = FavoriteTileView()
      tile.bind(favorite)
      tile.tag = index
      tile.addTarget(self, action: #selector(didTapFavorite(_:)), for: .touchUpInside)
      row.addArrangedSubview(tile)
      favoriteTiles.append(tile)
      tile.widthAnchor.constraint(equalToConstant: 156).isActive = true
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

      horizontalScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
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

    let detailViewController = FavoriteDetailViewController(
      favorites: favorites,
      initialIndex: sender.tag
    ) { [weak self] newIndex in
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
    button.layer.cornerRadius = 22
    button.layer.cornerCurve = .continuous
    button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
    return button
  }

  private func makeRoundButton(imageName: String, color: UIColor) -> UIButton {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: imageName), for: .normal)
    button.backgroundColor = color
    button.tintColor = .white
    button.layer.cornerRadius = 22
    button.layer.cornerCurve = .continuous
    return button
  }

  private func makeSquareAction(imageName: String) -> UIButton {
    let button = makeRoundButton(imageName: imageName, color: ExampleTheme.cardBackground)
    button.tintColor = .label
    button.accessibilityLabel = "All services"
    return button
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .systemFont(ofSize: 20, weight: .bold)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .label
    return label
  }

  private func openPromotion(at index: Int) {
    currentPromotionIndex = index
    selectedPromotionCard = (
      whatsNewCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? PromotionCardCell
    )?.cardView
    let pager = PromotionsPagerViewController(
      promotions: promotions,
      initialIndex: index
    ) { [weak self] newIndex in
      self?.currentPromotionIndex = newIndex
      self?.scrollWhatsNewToPromotion(at: newIndex, animated: false)
      self?.selectedPromotionCard = (
        self?.whatsNewCollectionView.cellForItem(at: IndexPath(item: newIndex, section: 0)) as? PromotionCardCell
      )?.cardView
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
    whatsNewCollectionView.scrollToItem(
      at: IndexPath(item: index, section: 0),
      at: .centeredHorizontally,
      animated: animated
    )
  }
}

extension RootViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    promotions.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: PromotionCardCell.reuseIdentifier,
      for: indexPath
    ) as! PromotionCardCell
    cell.bind(promotions[indexPath.item])
    return cell
  }
}

extension RootViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    openPromotion(at: indexPath.item)
  }
}

extension RootViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let isLandscape = view.bounds.width > view.bounds.height
    return CGSize(width: isLandscape ? 100 : 104, height: isLandscape ? 122 : 142)
  }
}
