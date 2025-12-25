//
//  RootViewController.swift
//  Example
//
//  Created by Phanith Ny on 8/12/25.
//

import EasyAnchor
import PHInteractiveDismissible
import UIKit

final class RootViewController: UIViewController, ZoomTransitioning {

  private var sourceView: UIView? {
    (navigationItem.rightBarButtonItem?.value(forKey: "view") as? UIView)?.superview?.superview?.superview?.superview?.superview?.superview?.superview?.superview?.superview?.superview
  }
  
  var sharedFrame: CGRect {
    if tapBarItem, let sourceView {
      let frame = sourceView.convert(sourceView.bounds, to: nil)
      return frame
    }
    return selectedCell!.iconContainerView.convert(selectedCell!.iconContainerView.bounds, to: nil)
  }
  
  var config: PHInteractiveDismissible.ZoomTransitionConfig? {
    return .init(
      duration: 0.5,
      maskVisualEffect: nil,
      dimmingColor: UIColor.black.withAlphaComponent(0.25),
      dimmingVisualEffect: nil,
      sourceView: tapBarItem ? sourceView : selectedCell?.iconContainerView
    )
  }
  
  // MARK: - Properties
  
  var delegate = PHZoomTransitioningDelegate(interactionController: nil)
  private var selectedCell: GridCell?
  private var tapBarItem: Bool = false
  
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
  
  private lazy var collectionView: UICollectionView = {
    let layout = createLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemBackground
    collectionView.register(GridCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.dataSource = self
    collectionView.delegate = self
    return collectionView
  }()
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    prepareLayouts()
  }
  
  // MARK: - Actions
  
  @objc
  private func push() {
    let controller = DetailsViewController()
    let navigationController = UINavigationController(rootViewController: controller)
    present(navigationController, dismissalType: .interactive, animated: true)
  }
  
  @objc
  private func back(_ sender: UIBarButtonItem) {
    tapBarItem = true
    let controller = DetailsViewController()
    let navigationController = UINavigationController(rootViewController: controller)
    
    if #available(iOS 26.0, *) {
      navigationController.preferredTransition = .zoom(sourceBarButtonItemProvider: { context in
        sender
      })
    } else if #available(iOS 18.0, *) {
      navigationController.preferredTransition = .zoom(sourceViewProvider: { context in
        sender.value(forKey: "view") as? UIView
      })
    }
    
    present(navigationController, animated: true)
  }
  
  private func zoom(from indexPath: IndexPath) {
    tapBarItem = false
    selectedCell = collectionView.cellForItem(at: indexPath) as? GridCell
    
    let controller = DetailsViewController()
    let navigationController = UINavigationController(rootViewController: controller)
    delegate = .init(interactionController: nil)
    
    if indexPath.item > 0 {
      navigationController.transitioningDelegate = delegate
      navigationController.modalPresentationStyle = .custom
    } else {
      if #available(iOS 18.0, *) {
        navigationController.preferredTransition = .zoom(sourceViewProvider: { [self] context in
          selectedCell?.iconContainerView
        })
      }
    }
    
    present(navigationController, animated: true)
  }
  
  // MARK: - Layouts
  
  private func createLayout() -> UICollectionViewCompositionalLayout {
    let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
      // Each item size
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(0.5))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      
      // The 2 vertical group
      let verticalGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0), heightDimension: .estimated(90.0))
      let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitems: [item, item])
      verticalGroup.interItemSpacing = .fixed(16)
      verticalGroup.edgeSpacing = .init(leading: nil, top: .fixed(16), trailing: nil, bottom: nil)
      
      // The 3 horizontal group
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [verticalGroup, verticalGroup, verticalGroup])
      group.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
      
      // The main group
      let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
      let mainGroup = NSCollectionLayoutGroup.horizontal(layoutSize: mainGroupSize, subitems: [group])
      
      let section = NSCollectionLayoutSection(group: mainGroup)
      section.orthogonalScrollingBehavior = .groupPagingCentered
      
      return section
    }
    return layout
  }
  
  private func prepareLayouts() {
    title = "Home"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Push", style: .plain, target: self, action: #selector(push))
    
    let barItem = UIBarButtonItem.init(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back(_:)))
    navigationItem.leftBarButtonItem = barItem
    
//    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//      print(barItem.value(forKey: "view"), barItem.customView)
//    }
    
    collectionView.layout {
      view.addSubview($0)
      $0.top()
        .leading()
        .trailing()
        .height(400)
    }
  }
}

// MARK: - UICollectionViewDataSource

extension RootViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let item = items[indexPath.item]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
    cell.bind(item)
    return cell
  }
}

// MARK: - UICollectionViewDelegate

extension RootViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    zoom(from: indexPath)
  }
}
