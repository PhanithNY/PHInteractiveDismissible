//
//  PromotionsPagerViewController.swift
//  Example
//
//  Created by Codex on 21/5/26.
//

import PHInteractiveDismissible
import UIKit

final class PromotionsPagerViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {
  var dismissibleScrollView: UIScrollView? { nil }

  var interactiveDismissShouldBegin: (() -> Bool)? {
    { [weak self] in
      self?.navigationController?.viewControllers.count == 1
    }
  }

  var zoomOption: PHInteractiveDismissible.ZoomOptions? {
    .init(
      duration: 0.35,
      maskVisualEffect: UIBlurEffect(style: .systemThickMaterial),
      dimmingColor: UIColor.black.withAlphaComponent(0.16),
      dimmingVisualEffect: nil
    )
  }

  private let promotions: [Promotion]
  private var currentIndex: Int
  private let onIndexChange: (Int) -> Void
  private let pageViewController: UIPageViewController

  init(promotions: [Promotion], initialIndex: Int, onIndexChange: @escaping (Int) -> Void) {
    self.promotions = promotions
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
    view.backgroundColor = ExampleTheme.pageBackground
    navigationItem.leftBarButtonItem = .init(image: UIImage(systemName: "chevron.down"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(dismissSelf))
    navigationItem.title = promotions[currentIndex].title

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
    guard promotions.indices.contains(index) else { return }

    let page = PromotionPageViewController(promotion: promotions[index], index: index)
    pageViewController.setViewControllers([page], direction: direction, animated: animated)
    currentIndex = index
    navigationItem.title = promotions[index].title
    if notifySourceChange {
      onIndexChange(index)
    }
  }

  @objc
  private func dismissSelf() {
    dismiss(animated: true)
  }
}

extension PromotionsPagerViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let page = viewController as? PromotionPageViewController else { return nil }
    let previousIndex = page.index - 1
    guard promotions.indices.contains(previousIndex) else { return nil }
    return PromotionPageViewController(promotion: promotions[previousIndex], index: previousIndex)
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let page = viewController as? PromotionPageViewController else { return nil }
    let nextIndex = page.index + 1
    guard promotions.indices.contains(nextIndex) else { return nil }
    return PromotionPageViewController(promotion: promotions[nextIndex], index: nextIndex)
  }
}

extension PromotionsPagerViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool) {
    guard completed,
          let page = pageViewController.viewControllers?.first as? PromotionPageViewController else {
      return
    }

    currentIndex = page.index
    navigationItem.title = promotions[page.index].title
    onIndexChange(page.index)
  }
}

private final class PromotionPageViewController: UIViewController {
  let index: Int
  private let promotion: Promotion
  private let cardView = PromotionCardView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  init(promotion: Promotion, index: Int) {
    self.promotion = promotion
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

    cardView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    cardView.bind(promotion)

    titleLabel.text = promotion.title
    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center

    subtitleLabel.text = promotion.subtitle
    subtitleLabel.font = .preferredFont(forTextStyle: .title3)
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.numberOfLines = 0
    subtitleLabel.textAlignment = .center
    subtitleLabel.textColor = .secondaryLabel

    view.addSubview(cardView)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
      cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
      cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
      cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.82),

      titleLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 32),
      titleLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      subtitleLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)
    ])
  }
}
