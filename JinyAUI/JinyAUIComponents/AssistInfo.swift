//
//  AssistInfo.swift
//  AUIComponents
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation

public class AssistInfo {
    
    /// A boolean value to set anchor clickable
    var anchorClickable: Bool?
    
    /// A string to set url for html
    var htmlUrl: String?
    
    /// A boolean value to set anchor highlight
    var highlightAnchor: Bool?
    
    /// A layoutInfo property for the type LayoutInfo
    public var layoutInfo: LayoutInfo?

    /// A extraProps property for the type ExtraProps
    public var extraProps: ExtraProps?

    /// - Parameters:
    ///   - assistDict: A dictionary for the type AssistInfo.
    public init(withDict assistDict: Dictionary<String,Any>) {
        
        if let layoutInfo = assistDict["layout_info"] as? Dictionary<String, Any> {
            
           self.layoutInfo = LayoutInfo(withDict: layoutInfo)
        }
        
        if let highlightAnchor = assistDict["highlight_anchor"] as? Bool {
            
           self.highlightAnchor = highlightAnchor
        }
        
        if let anchorClickable = assistDict["anchor_clickable"] as? Bool {
            
           self.anchorClickable = anchorClickable
        }
        
        self.htmlUrl = assistDict["html_url"] as? String
    }
}
