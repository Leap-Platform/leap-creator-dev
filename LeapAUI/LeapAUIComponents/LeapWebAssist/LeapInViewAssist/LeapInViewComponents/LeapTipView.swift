//
//  LeapTipView.swift
//  LeapAUI
//
//  Created by Ajay S on 12/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

/// enum type for Highlight
enum LeapHighlightType: String {
    
    case circle = "circle"
    case rect = "rect"
    case capsule = "capsule"
}

/// Type which controls LeapToolTip, LeapHighlight and LeapSpot.
class LeapTipView: LeapInViewAssist {
    
    /// toolTipView which carries webView.
    var toolTipView = UIView(frame: .zero)
    
    /// original isUserInteractionEnabled boolean value of the toView.
    var toViewOriginalInteraction: Bool?
    
    /// A view frame to highlight the source view to which tooltip is pointed to.
    var highlightType: LeapHighlightType = .rect
    
    /// spacing of the highlight area.
    var highlightSpacing = 10.0
    
    /// spacing of the highlight area after manipulation
    var manipulatedHighlightSpacing = 10.0
    
    /// method called to auto focus on the target view of the aui component.
    func setupAutoFocus() {
        
        var targetView: UIView?
        
        if let toView = self.toView as? UITextField {
            
            targetView = toView
        }
        
        if targetView == nil, let toViewParent = toView?.superview as? UITextField {
           
            targetView = toViewParent
        }
        
        if let toView = self.toView as? UITextView {
            
            targetView = toView
        }
        
        if targetView == nil, let toViewParent = toView?.superview as? UITextView {
           
            targetView = toViewParent
        }
        
        guard let focusView = targetView else {
            
            return
        }
        
        var isEditableView = false
        
        switch focusView {
        
        case is UITextField: isEditableView = true
        case is UITextView:
            if let view = toView as? UITextView {
                
                if view.isEditable {
                    
                    isEditableView = true
                }
            }
        default: isEditableView = false
        }
        
        if isEditableView && (assistInfo?.autoFocus ?? false) {
            
            focusView.becomeFirstResponder()
        }
    }
    
    override func remove(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        
        if let userInteraction = toViewOriginalInteraction {
            
            toView?.isUserInteractionEnabled = userInteraction
        }
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitTestView = super.hitTest(point, with: event)
        
        guard let viewToCheck = toView else {
            
            return hitTestView
        }
                
        let frameForToView = getGlobalToViewFrame()
        
        if frameForToView.contains(point) {
            
            if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) && (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                
                remove(byContext: false, byUser: true, autoDismissed: false, panelOpen: false, action: nil)
                
                return hitTestView
            
            } else {
                
                return viewToCheck
            }
                        
        } else {
            
            return hitTestView
        }
    }
}
