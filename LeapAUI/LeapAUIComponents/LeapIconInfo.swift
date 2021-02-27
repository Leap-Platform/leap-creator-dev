//
//  LeapIconInfo.swift
//  LeapAUI
//
//  Created by mac on 13/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapIconInfo {
    
    /// property which depicts whether the icon is left aligned or not.
    var isLeftAligned: Bool?
    
    /// property which depicts whether the icon is enabled or not.
    var isEnabled: Bool?
    
    /// background color of icon of type string.
    var backgroundColor: String?
    
    /// html string to load webView
    var htmlUrl: String?
    
    /// initialises IconInfo.
    /// - Parameters:
    ///   - iconDict: A dictionary value for the type IconInfo.
    init(withDict iconDict: Dictionary<String, Any>) {
        
        if let isLeftAligned = iconDict[constant_leftAlign] as? Bool {
            
            self.isLeftAligned = isLeftAligned
        }
        
        if iconDict.isEmpty {
            
            self.isEnabled = false
        
        } else {
            
            self.isEnabled = true
        }
        
        if let backgroundColor = iconDict[constant_bgColor] as? String {
            
            self.backgroundColor = backgroundColor
        }
        
        if let htmlUrl = iconDict[constant_htmlUrl] as? String {
            
            self.htmlUrl = htmlUrl
        }
    }
}
