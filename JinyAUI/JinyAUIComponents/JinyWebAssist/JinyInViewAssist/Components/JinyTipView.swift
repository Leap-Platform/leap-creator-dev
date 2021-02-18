//
//  JinyTipView.swift
//  JinyAUI
//
//  Created by Ajay S on 12/01/21.
//  Copyright © 2021 Jiny Inc. All rights reserved.
//

import Foundation
import UIKit

/// Type which controls JinyToolTip, JinyHighlight and JinySpot.
public class JinyTipView: JinyInViewAssist {
    
    /// toolTipView which carries webView.
    var toolTipView = UIView(frame: .zero)
    
    /// original isUserInteractionEnabled boolean value of the toView.
    var toViewOriginalInteraction: Bool?
    
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
    
    public override func remove(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        toolTipView.removeFromSuperview()
        
        if let userInteraction = toViewOriginalInteraction {
            
            toView?.isUserInteractionEnabled = userInteraction
        }
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitTestView = super.hitTest(point, with: event)
        
        guard let viewToCheck = toView else {
            
            return hitTestView
        }
        
        guard let frameForKw = viewToCheck.superview?.convert(viewToCheck.frame, to: nil) else {
            
            return hitTestView
        }
        
        if frameForKw.contains(point) {
            
            if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) && (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                
                remove(byContext: false, byUser: true, autoDismissed: false, panelOpen: false, action: nil)
            }
            
            return hitTestView
            
        } else {
            
            return hitTestView
        }
    }
}
