//
//  AssistInfo.swift
//  JinyDemo
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation

public class AssistInfo {
    
    /// A boolean value to set highlight clickable
    var highlightClickable: Bool?
    
    /// A string to set url for html
    var htmlUrl: String?
    
    /// A boolean value to set anchor highlight
    var highlightAnchor: Bool?
    
    /// A boolean value to set autoFocus to true only when highlightAnchor and highlightClickable are true.
    var autoFocus: Bool = false         // default is false
    
    /// A layoutInfo property for the type LayoutInfo
    public var layoutInfo: LayoutInfo?

    /// A extraProps property for the type ExtraProps
    public var extraProps: ExtraProps?

    /// - Parameters:
    ///   - assistDict: A dictionary for the type AssistInfo.
    public init(withDict assistDict: Dictionary<String,Any>) {
        
        if let layoutInfo = assistDict[constant_layoutInfo] as? Dictionary<String, Any> {
            
           self.layoutInfo = LayoutInfo(withDict: layoutInfo)
        }
        
        if let highlightAnchor = assistDict[constant_highlightAnchor] as? Bool {
            
           self.highlightAnchor = highlightAnchor
        }
        
        if let highlightClickable = assistDict[constant_highlightClickable] as? Bool {
            
           self.highlightClickable = highlightClickable
        }
        
        autoFocus = (highlightAnchor ?? false) && (highlightClickable ?? false)
        
        if let extraProps = assistDict[constant_extraProps] as? Dictionary<String, Any> {
            
            self.extraProps = ExtraProps(props: extraProps)
        }
        
        self.htmlUrl = assistDict[constant_htmlUrl] as? String
    }
}
