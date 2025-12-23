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
  
  var sharedFrame: CGRect {
    view.bounds
  }
  
  var config: PHInteractiveDismissible.ZoomTransitionConfig? {
    return .init(
      duration: 0.35,
      curve: CAMediaTimingFunction(controlPoints: 0.57, 0.27, 0.21, 0.97),
      maskCornerRadius: UIScreen.main.displayCornerRadius,
      overlayOpacity: 0.5,
      interactionScaleFactor: 0.6,
      placeholderColor: .clear,
      sourceView: view
    )
  }
  
  func prepare(for transition: PHInteractiveDismissible.PHZoomTransitioning.Transition) {
    
  }
  
  
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
    navigationItem.leftBarButtonItem = .init(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(dismissSelf))
    
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
    
  }
  
  public var config: PHInteractiveDismissible.ZoomTransitionConfig? {
    (topViewController as? ZoomTransitioning)?.config
  }
}
