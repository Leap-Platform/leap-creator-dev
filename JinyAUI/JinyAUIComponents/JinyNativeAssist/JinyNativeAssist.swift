//
//  JinyNativeAssist.swift
//  JinyDemo
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

/// A super class for the JinyNativeAssist AUI Components.
public class JinyNativeAssist: UIView, JinyAssist {
    
    public weak var delegate: JinyAssistDelegate?
    
    public var style: Style?
    
    public var assistInfo: AssistInfo?
    
    public func applyStyle(style: Style) {
        
    }
    
    public func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?) {
        
    }
    
    public func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    public func show() {
      
        delegate?.didPresentAssist()
    }
    
    public func performEnterAnimation(animation: String) {
        
    }
    
    public func hide(withAnim: Bool) {
        
    }
    
    public func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen:Bool, action: Dictionary<String, Any>?) {
    }
    
    public func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        
    }

}
