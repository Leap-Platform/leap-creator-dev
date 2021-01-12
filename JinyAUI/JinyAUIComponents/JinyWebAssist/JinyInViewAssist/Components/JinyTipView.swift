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
    
    public override func remove() {
        
        toolTipView.removeFromSuperview()
        
        if let userInteraction = toViewOriginalInteraction {
            
           toView?.isUserInteractionEnabled = userInteraction
        }
        
        performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out")
        
        super.remove()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let viewToCheck = toView {
            
            guard let frameForKw = viewToCheck.superview?.convert(viewToCheck.frame, to: nil) else {
                
                return self
            }
            
            if frameForKw.contains(point) {
                
                if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) && (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                    
                    remove()
                }
                
                return nil
                
            } else {
                
                return self
            }
        }
        
        return self
    }
    
    func simulateTap(atPoint:CGPoint, onWebview:UIView, withEvent:UIEvent) {
                
         onWebview.hitTest(atPoint, with: withEvent)
    }
}
