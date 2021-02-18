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
class JinyNativeAssist: UIView, JinyAssist {
    
    weak var delegate: JinyAssistDelegate?
    
    var style: Style?
    
    var assistInfo: AssistInfo?
    
    func applyStyle(style: Style) {
        
    }
    
    func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?) {
        
    }
    
    func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    func show() {
      
        delegate?.didPresentAssist()
    }
    
    func performEnterAnimation(animation: String) {
        
    }
    
    func hide(withAnim: Bool) {
        
    }
    
    func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen:Bool, action: Dictionary<String, Any>?) {
    }
    
    func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        
    }

}
