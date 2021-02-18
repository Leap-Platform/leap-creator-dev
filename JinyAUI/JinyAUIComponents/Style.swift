//
//  Style.swift
//  JinyDemo
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation

class Style {
    
    /// background color of the overlay
    var bgColor: String?
    
    /// elevation of the content
    var elevation: Double?
    
    /// cornerRadius of the content
    var cornerRadius: Double?
    
    /// maxWidth of the content
    var maxWidth: Double?
    
    /// maxHeight of the content
    var maxHeight: Double?
    
    /// margin of the content
    var contentMargin: Int?
    
    /// stroke width of the margin
    var strokeWidth: Double?
    
    /// stroke color of the margin
    var strokeColor: String?
    
    /// A boolean value for the content to set to transparent
    var isContentTransparent: Bool?
    
    /// - Parameters:
    ///   - styleDict: A dictionary value for the type Style.
    init(withDict styleDict: Dictionary<String,Any>) {
        
        if let bgColor = styleDict[constant_bgColor] as? String {
            
            self.bgColor = bgColor
        }
        
        if let elevation = styleDict[constant_elevation] as? Double {
            
            self.elevation = elevation
        }
        
        if let cornerRadius = styleDict[constant_cornerRadius] as? Double {
            
            self.cornerRadius = cornerRadius
        }
        
        if let maxWidth = styleDict[constant_maxWidth] as? Double {
            
            self.maxWidth = maxWidth
        }
        
        if let maxHeight = styleDict[constant_maxHeight] as? Double {
            
            self.maxHeight = maxHeight
        }
        
        if let strokeColor = styleDict[constant_strokeColor] as? String {
            
            self.strokeColor = strokeColor
        }
        
        if let strokeWidth = styleDict[constant_strokeWidth] as? Double {
            
            self.strokeWidth = strokeWidth
        }
        
        if let contentTransparent = styleDict[constant_contentTransparent] as? Bool {
            
            self.isContentTransparent = contentTransparent
        }
    }
}

class ExtraProps {
    
    /// A dictionary value to specify extra properties
    var props: Dictionary<String, Any>
    
    /// - Parameters:
    ///   - props: A dictionary value for the type ExtraProps.
    init(props: Dictionary<String, Any>) {
        self.props = props
    }
}
