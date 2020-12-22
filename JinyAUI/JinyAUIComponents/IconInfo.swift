//
//  IconInfo.swift
//  JinyDemo
//
//  Created by mac on 13/10/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation

public class IconInfo {
    
    /// property which depicts whether the icon is left aligned or not.
    public var isLeftAligned: Bool?
    
    /// property which depicts whether the icon is enabled or not.
    public var isEnabled: Bool?
    
    /// background color of icon of type string.
    public var backgroundColor: String?
    
    /// html string to load webView
    public var htmlUrl: String?
    
    /// initialises IconInfo.
    /// - Parameters:
    ///   - iconDict: A dictionary value for the type IconInfo.
    init(withDict iconDict: Dictionary<String, Any>) {
        
        if let isLeftAligned = iconDict["isLeftAligned"] as? Bool {
            
            self.isLeftAligned = isLeftAligned
        }
        
        if let isEnabled = iconDict["isEnabled"] as? Bool {
            
            self.isEnabled = isEnabled
        }
        
        if let backgroundColor = iconDict["backgroundColor"] as? String {
            
            self.backgroundColor = backgroundColor
        }
        
        if let htmlUrl = iconDict["htmlUrl"] as? String {
            
            self.htmlUrl = htmlUrl
        }
    }
}
