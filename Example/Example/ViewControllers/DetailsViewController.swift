// 
//  DetailsViewController.swift
//  Example
//
//  Created by Phanith Ny on 8/12/25.
//

import EasyAnchor
import PHInteractiveDismissible
import UIKit

final class DetailsViewController: UIViewController, InteractiveDismissible, ZoomTransitioning {

  var dismissibleScrollView: UIScrollView? { nil }
  var interactiveTransitionManager: (any UIViewControllerTransitioningDelegate)?
  var preferredCornerRadius: CGFloat? {
    44
  }
  
  // MARK: - Properties
  
  private var items: [GridItem] = [
    .init(name: "Item 1", symbolName: "checkmark"),
    .init(name: "Item 2", symbolName: "folder"),
    .init(name: "Item 3", symbolName: "tray"),
    .init(name: "Item 4", symbolName: "paperclip"),
    .init(name: "Item 5", symbolName: "link"),
    .init(name: "Item 6", symbolName: "person"),
    .init(name: "Item 7", symbolName: "moon.zzz"),
    .init(name: "Item 8", symbolName: "snow"),
    .init(name: "Item 9", symbolName: "hurricane"),
    .init(name: "Item 10", symbolName: "umbrella"),
    .init(name: "Item 11", symbolName: "timelapse")
  ]
  
  private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).config {
    $0.backgroundColor = .systemGroupedBackground
    $0.dataSource = self
    $0.delegate = self
    $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }
  
  // MARK: - Init / Deinit
  
  init() {
    super.init(nibName: nil, bundle: nil)
    
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func loadView() {
    super.loadView()
    
    prepareLayouts()
  }
}

// MARK: - Actions

extension DetailsViewController {
  @objc
  private func dismissSelf() {
    dismiss(animated: true)
  }
}

// MARK: - UITableViewDelegate

extension DetailsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let detailViewController: DetailsViewController = .init()
    navigationController?.pushViewController(detailViewController, animated: true)
  }
}

// MARK: - UITableViewDataSource

extension DetailsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    items.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = items[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
    cell.textLabel?.text = item.name
    cell.imageView?.image = UIImage(systemName: item.symbolName)
    return cell
  }
}

// MARK: - Layouts

extension DetailsViewController {
  private func prepareLayouts() {
    title = "Lists"
    view.backgroundColor = .systemGroupedBackground
    
    if let viewControllers = navigationController?.viewControllers, viewControllers.count == 1 {
      navigationItem.leftBarButtonItem = .init(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(dismissSelf))
    }
    
    tableView.layout {
      view.addSubview($0)
      $0.fill()
    }
  }
}

extension UINavigationController: @retroactive ZoomTransitioning {
  
  public var sharedFrame: CGRect {
    (topViewController as? ZoomTransitioning)?.sharedFrame ?? .zero
  }
  
  public func prepare(for transition: PHInteractiveDismissible.PHZoomTransitioning.Transition) {
    (topViewController as? ZoomTransitioning)?.prepare(for: transition)
  }
  
  public var config: PHInteractiveDismissible.ZoomOptions? {
    (topViewController as? ZoomTransitioning)?.config
  }
}
