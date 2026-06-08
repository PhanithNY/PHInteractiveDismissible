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
      beginPresentingAppearanceTransitionForDismissal()
      return
    }
    
    beginPresentingAppearanceTransitionForDismissal()
    
    if !coordinator.isInteractive {
      coordinator.animate(alongsideTransition: { _ in
        self.fadeView.alpha = 0.0
      })
    }
    
    coordinator.notifyWhenInteractionEnds { [weak self] context in
      guard let self else { return }
      if context.isCancelled {
        self.cancelPresentingAppearanceTransitionForDismissal()
      } else {
        // Non-interactive dismissal completion is finalized in dismissalTransitionDidEnd.
      }
    }
  }

  public override func dismissalTransitionDidEnd(_ completed: Bool) {
    guard didBeginDismissalAppearanceTransition else {
      return
    }

    if completed {
      finishPresentingAppearanceTransitionForDismissal()
    } else {
      cancelPresentingAppearanceTransitionForDismissal()
    }
  }

  public override func containerViewDidLayoutSubviews() {
    super.containerViewDidLayoutSubviews()

    if let containerView {
      fadeView.frame = containerView.bounds
    }
  }

  private func beginPresentingAppearanceTransitionForDismissal() {
    guard !didBeginDismissalAppearanceTransition else { return }

    didBeginDismissalAppearanceTransition = true
    presentingViewController.beginAppearanceTransition(true, animated: true)
  }

  private func finishPresentingAppearanceTransitionForDismissal() {
    guard didBeginDismissalAppearanceTransition else { return }

    presentingViewController.endAppearanceTransition()
    didBeginDismissalAppearanceTransition = false
  }

  private func cancelPresentingAppearanceTransitionForDismissal() {
    presentingViewController.view.isHidden = true
    guard didBeginDismissalAppearanceTransition else { return }

    presentingViewController.beginAppearanceTransition(false, animated: true)
    presentingViewController.endAppearanceTransition()
    didBeginDismissalAppearanceTransition = false
  }
}
