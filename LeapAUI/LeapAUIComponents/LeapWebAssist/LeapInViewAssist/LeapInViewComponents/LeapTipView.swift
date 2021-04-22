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
    
    /// A view frame to highlight the source view to which tooltip is pointed to.
    var highlightType: LeapHighlightType = .rect
    
    /// spacing of the highlight area.
    var highlightSpacing = 10.0
    
    /// spacing of the highlight area after manipulation
    var manipulatedHighlightSpacing = 10.0
    
    /// boolean to know whether a tap on toView occured
    var tappedOnToView = false
    
    /// previous rect of the component to update
    var previousFrame: CGRect?
    
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
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        tappedOnToView = false
        
        let hitTestView = super.hitTest(point, with: event)
        
        guard let viewToCheck = toView else {
            
            return hitTestView
        }
                
        let frameForToView = getGlobalToViewFrame()
        
        if frameForToView.contains(point) {
            
            tappedOnToView = true 
            
            if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) && (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                                
                performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_anchor_click: true]])
                
                self.removeFromSuperview()
                                
                return viewToCheck
            
            } else if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) {
                                
                return viewToCheck
            
            } else {
                
                return hitTestView
            }
                        
        } else {
            
            return hitTestView
        }
    }
}
