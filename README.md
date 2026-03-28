# Welcome to PHInteractiveDismissible!

**PHInteractiveDismissible** provides two custom presentation styles for UIKit:

- interactive modal dismissal
- zoom presentation with interactive pan and pinch dismissal

## Interactive Dismissal
Make your view controller conform to `InteractiveDismissible`.

```swift
final class ChildInteractiveDismissibleListViewController: UIViewController, InteractiveDismissible {
  required init?(coder: NSCoder) {
    fatalError()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    backButtonEnabled = true
    title = "Child"
    view.backgroundColor = .systemBackground

    if backButtonEnabled {
      navigationItem.leftBarButtonItem = .init(
        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: self,
        action: #selector(dismissSelf)
      )
      navigationItem.rightBarButtonItem = .init(
        title: "Push",
        style: .plain,
        target: self,
        action: #selector(pushNext)
      )
    }
  }

  @objc
  private func dismissSelf() {
    dismiss(animated: true)
  }

  @objc
  private func pushNext() {
    navigationController?.pushViewController(SecondViewController(), animated: true)
  }
}
```

Present it with the built-in custom transition:

```swift
let viewController = ChildInteractiveDismissibleListViewController()
let navigationController = UINavigationController(rootViewController: viewController)
present(navigationController, dismissalType: .interactive, animated: true)
```

`UINavigationController` already conforms to `InteractiveDismissible`, so wrapping your screen in a navigation controller works out of the box.

## Zoom Transition
For zoom presentation, make the destination conform to both `InteractiveDismissible` and `ZoomTransitioning`.

```swift
final class DetailsViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {
  var zoomOption: ZoomOptions? {
    .init(
      duration: 0.35,
      maskVisualEffect: UIBlurEffect(style: .systemThickMaterial),
      dimmingColor: nil,
      dimmingVisualEffect: nil
    )
  }
}
```

If you already have a concrete source view, present like this:

```swift
let detailsViewController = DetailsViewController()
let navigationController = UINavigationController(rootViewController: detailsViewController)

zoom(to: navigationController, from: sender)
```

If your source view may change over time, such as a reusable collection view cell, use `sourceViewProvider`:

```swift
let detailsViewController = DetailsViewController()
let navigationController = UINavigationController(rootViewController: detailsViewController)

zoom(
  to: navigationController,
  sourceViewProvider: { [weak self] in
    self?.selectedCell?.iconContainerView
  }
)
```

You can also provide a custom source rect:

```swift
zoom(
  to: navigationController,
  from: sender,
  sourceRect: sender.bounds.insetBy(dx: 8, dy: 8)
)
```

`ZoomOptions` currently supports:

- `duration`
- `maskCornerRadius`
- `minimumScale`
- `maskVisualEffect`
- `dimmingColor`
- `dimmingVisualEffect`

## Installation
From Xcode menu bar:
1.  File
2.  Swift Packages
3.  Add Package Dependency...
4.  Paste the repo url  `https://github.com/PhanithNY/PHInteractiveDismissible.git`

## Author
PhanithNY, [ny.phanith.fe@gmail.com](mailto:ny.phanith.fe@gmail.com)

## License
PHInteractiveDismissible is available under the MIT license. See the LICENSE file for more info.
