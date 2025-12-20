// 
//  GridCell.swift
//  Example
//
//  Created by Phanith Ny on 8/12/25.
//

import EasyAnchor
import UIKit

func clone(label: UILabel) throws -> UILabel? {
  let archive = try NSKeyedArchiver.archivedData(withRootObject: label, requiringSecureCoding: false)
  // Define 3 classes here for UILabel, otherwise it throws an error
  return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UILabel.self, UIColor.self, UIFont.self], from: archive) as? UILabel
}

extension UIView {
  func clone(label: UILabel) throws -> UILabel? {
    let archive = try NSKeyedArchiver.archivedData(withRootObject: label, requiringSecureCoding: false)
    // Define 3 classes here for UILabel, otherwise it throws an error
    return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UILabel.self, UIColor.self, UIFont.self], from: archive) as? UILabel
  }
}

final class GridItemView: UIView {

}

final class GridCell: UICollectionViewCell {
  
  // MARK: - Properties
  
  private(set) lazy var iconContainerView = UIView().config {
    $0.backgroundColor = .red
  }
  
  private lazy var iconView = UIImageView().config {
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .label
  }
  
  private lazy var titleLabel = UILabel().config {
    $0.font = .preferredFont(forTextStyle: .footnote)
    $0.textAlignment = .center
    $0.textColor = .label
  }
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    prepareLayouts()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    prepareLayouts()
  }
  
  // MARK: - Actions
  
  final func bind(_ item: GridItem) {
    titleLabel.text = item.name
    iconView.tintColor = .label
    iconView.image = UIImage(systemName: item.symbolName)
  }
  
  // MARK: - Prepare layouts
  
  private func prepareLayouts() {
    contentView.backgroundColor = .systemBackground
    
    iconContainerView.layout {
      contentView.addSubview($0)
      $0.top(8)
        .centerX()
        .size(equalTo: 72, priority: .defaultHigh)
        .layer.cornerRadius = 10//72/2
    }
    
    titleLabel.layout {
      contentView.addSubview($0)
      $0.top(constraint: iconContainerView.bottomAnchor, 8)
        .leading()
        .trailing()
        .bottom()
    }
    
    iconView.layout {
      iconContainerView.addSubview($0)
      $0.center()
        .size(equalTo: 72 / 2)
    }
  }
}
