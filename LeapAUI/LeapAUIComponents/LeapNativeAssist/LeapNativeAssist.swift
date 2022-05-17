//
//  LeapNativeAssist.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

/// A super class for the LeapNativeAssist AUI Components.
class LeapNativeAssist: UIView, LeapAssist {
    
    weak var delegate: LeapAssistDelegate?
    
    var style: LeapStyle?
    
    var assistInfo: LeapAssistInfo?
    
    var projectParameters: LeapProjectParameters?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setAccessibilityLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setAccessibilityLabel() {
        switch self {
        case is LeapBeacon: self.accessibilityLabel = constant_leapBeacon
        case is LeapPointer: self.accessibilityLabel = constant_leapGesture
        default: print("Not Identified")
        }
    }
    
    func applyStyle(style: LeapStyle) {
        
    }
    
    func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?) {
        
    }
    
    func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    func show() {
      
        delegate?.didPresentAssist()
    }
    
    func remove() {
        self.removeFromSuperview()
    }
    
    func performEnterAnimation(animation: String) {
        
    }
    
    func hide() {
        self.isHidden = true
    }
    
    func unhide() {
        self.isHidden = false
    }
    
    func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen:Bool, action: Dictionary<String, Any>?) {
        remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?, isReinitialize: Bool = false) {
        self.removeFromSuperview()
        guard !isReinitialize else { return }
        self.delegate?.didDismissAssist(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
}
