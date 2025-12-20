//
//  ZoomOptions.swift
//  PHInteractiveDismissible
//
//  Created by Phanith Ny on 9/12/25.
//

import UIKit

open class ZoomOptions : NSObject { //NSCopying
  
  /// Called when an interactive dismissal of this transition begins.
  /// Return value indicates whether the interaction should begin for the given context.
  open var interactiveDismissShouldBegin: ((ZoomOptions.InteractionContext) -> Bool)?
  
  /// Dimming color to apply to the content behind the zoomed in view. Set to nil to use the default.
  open var dimmingColor: UIColor?
  
  /// Visual effect to apply to the content behind the zoomed in view. Defaults to nil.
  open var dimmingVisualEffect: UIBlurEffect?
  
  open class InteractionContext : NSObject {
    
    /// Location of the interaction in the displayed view controller's view's coordinate space.
//    open var location: CGPoint { get }
    
    /// The interaction's velocity.
//    open var velocity: CGVector { get }
    
    /// Whether the interaction would begin under the current conditions by default.
//    open var willBegin: Bool { get }
  }
  
  open class AlignmentRectContext : NSObject {
    
    /// The transition's source view.
//    open var sourceView: UIView { get }
    
    /// The zoomed view controller.
//    open var zoomedViewController: UIViewController { get }
  }
  
}
