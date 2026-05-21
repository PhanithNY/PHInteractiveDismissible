//
//  FavoriteDetailViewController.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import PHInteractiveDismissible
import UIKit

final class FavoriteDetailViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {
  var dismissibleScrollView: UIScrollView? { nil }

  var zoomOption: PHInteractiveDismissible.ZoomOptions? {
    .init(
      duration: 0.35,
      maskVisualEffect: UIBlurEffect(style: .systemThickMaterial),
      dimmingColor: UIColor.black.withAlphaComponent(0.14),
      dimmingVisualEffect: nil
    )
  }

  private let favorites: [FavoriteItem]
  private var currentIndex: Int
  private let onIndexChange: (Int) -> Void
  private let pageViewController: UIPageViewController

  init(favorites: [FavoriteItem], initialIndex: Int, onIndexChange: @escaping (Int) -> Void) {
    self.favorites = favorites
    self.currentIndex = initialIndex
    self.onIndexChange = onIndexChange
    self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                   navigationOrientation: .horizontal)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareLayout()
    showPage(at: currentIndex, direction: .forward, animated: false, notifySourceChange: false)
  }

  private func prepareLayout() {
    title = favorites[currentIndex].title
    view.backgroundColor = ExampleTheme.pageBackground
    navigationItem.leftBarButtonItem = .init(image: UIImage(systemName: "chevron.down"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(dismissSelf))

    addChild(pageViewController)
    pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pageViewController.view)
    pageViewController.didMove(toParent: self)
    pageViewController.dataSource = self
    pageViewController.delegate = self

    NSLayoutConstraint.activate([
      pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func showPage(at index: Int,
                        direction: UIPageViewController.NavigationDirection,
                        animated: Bool,
                        notifySourceChange: Bool = true) {
    guard favorites.indices.contains(index) else { return }

    let page = FavoritePageViewController(favorite: favorites[index], index: index)
    pageViewController.setViewControllers([page], direction: direction, animated: animated)
    currentIndex = index
    title = favorites[index].title
    if notifySourceChange {
      onIndexChange(index)
    }
  }

  @objc
  private func dismissSelf() {
    dismiss(animated: true)
  }
}

extension FavoriteDetailViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let page = viewController as? FavoritePageViewController else { return nil }
    let previousIndex = page.index - 1
    guard favorites.indices.contains(previousIndex) else { return nil }
    return FavoritePageViewController(favorite: favorites[previousIndex], index: previousIndex)
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let page = viewController as? FavoritePageViewController else { return nil }
    let nextIndex = page.index + 1
    guard favorites.indices.contains(nextIndex) else { return nil }
    return FavoritePageViewController(favorite: favorites[nextIndex], index: nextIndex)
  }
}

extension FavoriteDetailViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool) {
    guard completed,
          let page = pageViewController.viewControllers?.first as? FavoritePageViewController else {
      return
    }

    currentIndex = page.index
    title = favorites[page.index].title
    onIndexChange(page.index)
  }
}

private final class FavoritePageViewController: UIViewController {
  let index: Int
  private let favorite: FavoriteItem
  private let cardView = FavoriteTileView()

  init(favorite: FavoriteItem, index: Int) {
    self.favorite = favorite
    self.index = index
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
    view.backgroundColor = ExampleTheme.pageBackground

    cardView.bind(favorite)
    cardView.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = favorite.title
    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
    titleLabel.textAlignment = .center
    titleLabel.adjustsFontForContentSizeCategory = true

    let subtitleLabel = UILabel()
    subtitleLabel.text = favorite.subtitle
    subtitleLabel.font = .preferredFont(forTextStyle: .title3)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.adjustsFontForContentSizeCategory = true

    let actionButton = UIButton(type: .system)
    actionButton.setTitle("Send \(favorite.amount)", for: .normal)
    actionButton.setTitleColor(.white, for: .normal)
    actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    actionButton.backgroundColor = favorite.color
    actionButton.layer.cornerRadius = 24
    actionButton.layer.cornerCurve = .continuous

    [cardView, titleLabel, subtitleLabel, actionButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview($0)
    }

    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 92),
      cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
      cardView.heightAnchor.constraint(equalToConstant: 168),

      titleLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 34),
      titleLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
      subtitleLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

      actionButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 34),
      actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
      actionButton.heightAnchor.constraint(equalToConstant: 52)
    ])
  }
}
