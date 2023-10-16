//
//  InteractiveTransitioning.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public protocol InteractiveTransitioning: UIViewControllerInteractiveTransitioning {
  var interactionInProgress: Bool { get }
}
