//
//  PHModalPresentationController.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public final class PHModalPresentationController: UIPresentationController {
  
  // MARK: - Properties
  
  private(set) lazy var fadeView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    view.alpha = 0
    return view
  }()
  
  // MARK: - Override
  
  public override var shouldRemovePresentersView: Bool {
    false
  }
  
  public override var shouldPresentInFullscreen: Bool {
    true
  }
  
  public override func presentationTransitionDidEnd(_ completed: Bool) {
    if completed {
      presentingViewController.view.isHidden = true
    }
  }
  
  public override func presentationTransitionWillBegin() {
    guard let containerView = containerView else { return }
    containerView.insertSubview(fadeView, at: 0)
    fadeView.frame = containerView.bounds
    
    guard let coordinator = presentedViewController.transitionCoordinator else {
      fadeView.alpha = 0.50
      return
    }
    
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.fadeView.alpha = 0.50
    })
  }
  
  public override func dismissalTransitionWillBegin() {
    presentingViewController.view.isHidden = false
    guard let coordinator = presentedViewController.transitionCoordinator else {
      fadeView.alpha = 0.0
      return
    }
    
    if !coordinator.isInteractive {
      coordinator.animate(alongsideTransition: { _ in
        self.fadeView.alpha = 0.0
      })
    }
  }
}
