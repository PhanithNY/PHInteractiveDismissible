# Welcome to PHInteractiveDismissible!

**PHInteractiveDismissible** allow you to interactively dismiss custom UIViewController.


## Usage
Make your UIViewController conform to **InteractivePresentable**.

``` swift
final class ChildInteractiveDismissibleListViewController: UIViewController, InteractivePresentable {
  var transitionManager: UIViewControllerTransitioningDelegate?
  
  init() {
    super.init(nibName: nil, bundle: nil)
    
    backButtonEnabled = true
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
  override func loadView() {
    super.loadView()
    
    title = "Child"
    view.backgroundColor = .background
   
    if backButtonEnabled {
      if #available(iOS 13.0, *) {
        navigationItem.leftBarButtonItem = .init(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(_dismiss))
        navigationItem.rightBarButtonItem = .init(title: "Push", style: .plain, target: self, action: #selector(pushNext))
      }
    }
  }
  
  @objc
  private func _dismiss() {
    self.dismiss(animated: true)
  }
  
  @objc
  private func pushNext() {
    let viewController = SecondViewController()
    navigationController?.pushViewController(viewController, animated: true)
  }
}
```

And present it like:
``` swift 
let viewController = ChildInteractiveDismissibleListViewController()
let navigationController: UINavigationController = .init(rootViewController: viewController)
present(navigationController, dismissalType: .interactive, animated: true)
```

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
