//
//  OneWayPanGestureDirection.swift
//
//
//  Created by Phanith on 16/10/23.
//

import UIKit

public enum OneWayPanGestureDirection {
  case left
  case right
  case top
  case bottom
  
  var edges: UIRectEdge {
    switch self {
    case .left:
      return .left
      
    case .right:
      return .right
      
    case .top:
      return .top
      
    case .bottom:
      return .bottom
    }
  }
}

public final class OneWayPanGestureRecognizer: UIScreenEdgePanGestureRecognizer {//UIPanGestureRecognizer {
  var drag: Bool = false
  var moveX: Int = 0
  var moveY: Int = 0
  var direction: OneWayPanGestureDirection = .left
  
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    
    if state == .failed {
      return
    }
    
    let touch: UITouch = unsafeDowncast(touches.first.unsafelyUnwrapped, to: UITouch.self)
    let nowPoint: CGPoint = touch.location(in: view)
    let prevPoint: CGPoint = touch.previousLocation(in: view)
    moveX += Int(prevPoint.x - nowPoint.x)
    moveY += Int(prevPoint.y - nowPoint.y)
    
    if !drag {
      if direction == .left || direction == .right {
        if moveX == 0 {
          drag = false
        } else if (direction == .left && moveX > 0) {//|| (direction == .right && moveX < 0) {
          state = .failed
        } else {
          drag = true
        }
      } else {
        if moveY == 0 {
          drag = false
        } else if (direction == .top && moveY > 0) {//|| (direction == .bottom && moveY < 0) {
          state = .failed
        } else {
          drag = true
        }
      }
    }
  }
  
  public override func reset() {
    super.reset()
    drag = false
    moveX = 0
    moveY = 0
  }
}
