//
//  LeapDraggable.swift
//  LeapAUI
//
//  Created by Ajay S on 26/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapDraggableDelegate: AnyObject {
    
    func iconDidDrag()
    func iconDidRelease(atLocation location: CGPoint)
}

class LeapDraggable: UIPanGestureRecognizer {
    
    weak var draggableDelegate: LeapDraggableDelegate?
    
    var lastLocation: CGPoint = .zero
    
    init() {
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(didPanHappen(_:)))
        self.delegate = self
    }
    
    @objc func didPanHappen(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        
        if sender.state == .began {
            
            if let viewToDrag = sender.view {
                lastLocation = viewToDrag.center
            }
            
        } else if sender.state == .changed {
            
            if let viewToDrag = sender.view {
                
                guard let superView = viewToDrag.superview else { return }
                
                if (viewToDrag.frame.origin.y + translation.y) > mainIconBottomConstant && (viewToDrag.frame.origin.y + translation.y) <= (superView.frame.maxY - mainIconBottomConstant - viewToDrag.frame.height)  {
                    
                    viewToDrag.center = CGPoint(x: viewToDrag.center.x + translation.x,
                                                y: viewToDrag.center.y + translation.y)
                    sender.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
                    
                    self.draggableDelegate?.iconDidDrag()
                }
            }
        
        } else if sender.state == .ended {
                        
            var draggedLocation: CGPoint = .zero
            
            if let viewToDrag = sender.view {
                
                draggedLocation = viewToDrag.frame.origin
            
                self.draggableDelegate?.iconDidRelease(atLocation: draggedLocation)
            }
        }
    }
}

extension LeapDraggable: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
