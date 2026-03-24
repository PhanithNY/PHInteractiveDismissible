//
//  PHZoomPresentationController.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

public final class PHZoomPresentationController: UIPresentationController {
  
  // MARK: - Properties
  
  private(set) lazy var fadeView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
    view.alpha = 0
    return view
  }()

  private var didBeginDismissalAppearanceTransition = false
  
  // MARK: - Override
  
  public override var shouldRemovePresentersView: Bool {
    false
  }
  
  public override var shouldPresentInFullscreen: Bool {
    true
  }
  
  public override func presentationTransitionDidEnd(_ completed: Bool) {
    presentingViewController.endAppearanceTransition()
    if completed {
      presentingViewController.view.isHidden = true
    }
  }
  
  public override func presentationTransitionWillBegin() {
    presentingViewController.beginAppearanceTransition(false, animated: true)
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

    if coordinator.isInteractive {
      didBeginDismissalAppearanceTransition = true
      presentingViewController.beginAppearanceTransition(true, animated: true)
    } else {
      didBeginDismissalAppearanceTransition = true
      presentingViewController.beginAppearanceTransition(true, animated: true)
    }
    
    if !coordinator.isInteractive {
      coordinator.animate(alongsideTransition: { _ in
        self.fadeView.alpha = 0.0
      })
    }

    coordinator.notifyWhenInteractionEnds { [weak self] context in
      guard let self else { return }
      if context.isCancelled {
        self.presentingViewController.view.isHidden = true
        if self.didBeginDismissalAppearanceTransition {
          self.presentingViewController.beginAppearanceTransition(false, animated: true)
          self.presentingViewController.endAppearanceTransition()
          self.didBeginDismissalAppearanceTransition = false
        }
      } else {
        if self.didBeginDismissalAppearanceTransition {
          self.presentingViewController.endAppearanceTransition()
          self.didBeginDismissalAppearanceTransition = false
        }
      }
    }
  }
}
