//
//  LayoutInfo.swift
//  JinyDemo
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation

public class LayoutInfo {
    
    /// layout Alignment for the content
    public var layoutAlignment: String?
    
    /// enter animation for the content
    public var enterAnimation: String?
    
    /// exit animation for the content
    public var exitAnimation: String?
    
    /// property type of the type Style
    public var style: Style
    
    /// A boolean value to set outside dismiss
    public var outsideDismiss: Bool?
    
    /// An integer value to set time delay in ms
    public var autoDismissDelay: Float
    
    /// - Parameters:
    ///   - layoutDict: A dictionary for the type LayoutInfo.
    init(withDict layoutDict: Dictionary<String,Any>) {
        
        if let styleDict = layoutDict["style"] as? Dictionary<String,Any> {
        
            self.style = Style(withDict: styleDict)
        
        } else {
            
            self.style = Style(withDict: [:])
        }
        
        if let dismissAction = layoutDict["dismiss_action"] as? Dictionary<String,Any>, let outsideDismiss = dismissAction["outside_dismiss"] as? Bool {
            
            self.outsideDismiss = outsideDismiss
        }
        
        if let enterAnimation = layoutDict["enter_animation"] as? String {
            
            self.enterAnimation = enterAnimation
        }
        
        if let exitAnimation = layoutDict["exit_animation"] as? String {
            
            self.exitAnimation = exitAnimation
        }
        
        if let alignment = layoutDict["alignment"] as? String {
            
            self.layoutAlignment = alignment
        }
        
        self.autoDismissDelay = (layoutDict["auto_dismiss_delay"] as? Float ?? 0)/1000
    }
}

/// Types of Alignments for the AUIComponent
public enum JinyAlignmentType: String, CaseIterable {
    case topLeft = "top_left"
    case topCenter = "top_center"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomCenter = "bottom_center"
    case bottomRight = "bottom_right"
    case leftCenter = "left_center"
    case rightCenter = "right_center"
    case left = "left"
    case top = "top"
    case right = "right"
    case bottom = "bottom"
    case center = "center"
}

/// Types of animations that can be used for the AUIComponent
public enum JinyLayoutAnimationType: String, CaseIterable {
    case slideLeft = "slide_left"
    case slideTop = "slide_up"
    case slideRight = "slide_right"
    case slideBottom = "slide_down"
    case fadeIn = "fade_in"
    case fadeOut = "fade_out"
    case zoomIn = "zoom_in"
    case zoomOut = "zoom_out"
}
