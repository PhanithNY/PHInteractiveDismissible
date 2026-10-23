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

### ProMotion

To allow interactive transitions to render above 60 Hz on supported iPhones, enable the full
Core Animation frame-rate range in the host app's `Info.plist`:

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

This is a host-application setting and cannot be injected by a Swift package.

### Optional Scene Refresh Vote

Each window scene shares one refresh-vote display link. The default is `.automatic`,
which leaves the vote paused and lets iOS manage refresh without an additional request.
Selected controllers can update their scene's preference manually:

```swift
import PHInteractiveDismissible

final class ScrollingViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setProMotionRefreshRate(.fps120)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    setProMotionRefreshRate(.automatic)
  }
}
```

`PHProMotionRefreshRate` provides `.automatic`, `.fps30`, `.fps60`, `.fps90`, and `.fps120`.
You can also assign `windowScene.proMotionRefreshRate` directly. The controller helper
returns `false` if its view is not attached to a scene and does not load the view.

The link is created on the first manual request and reused for every subsequent rate
change, including transitions through automatic mode. Each assignment replaces the
scene's current preference. There are no per-controller registrations or automatic
visibility decisions: the app must restore the desired preference on navigation,
presentation, and cancelled transitions.

Scene inactivity or backgrounding pauses the existing link. Activation restores the
latest selected preference; `.automatic` remains paused. Different scenes keep separate
links and preferences. The scene owns its vote, which holds the scene weakly and does
not retain controllers. Scene teardown removes the observers and invalidates the link.

The extension builds with Xcode 26 and later and supports iOS 13 and later.
The link is bound to the scene's screen using the screen display-link API.
iOS 15+ uses `preferredFrameRateRange`; iOS
13–14 uses `preferredFramesPerSecond`. Requests are clamped to the display's maximum;
the actual rate remains system-controlled and may differ (including a 90 FPS request).
A request does not cap all UIKit animations in the scene. Higher rates can increase
power use. The host app still needs the Info.plist opt-in
above to request rates above 60 Hz on supported iPhones.

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
