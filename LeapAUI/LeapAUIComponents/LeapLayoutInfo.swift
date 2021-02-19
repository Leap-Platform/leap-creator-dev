//
//  LeapLayoutInfo.swift
//  LeapAUI
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapLayoutInfo {
    
    /// layout Alignment for the content
    var layoutAlignment: String?
    
    /// enter animation for the content
    var enterAnimation: String?
    
    /// exit animation for the content
    var exitAnimation: String?
    
    /// property of the type Style
    var style: LeapStyle
    
    /// property of the type DismissAction
    var dismissAction: LeapDismissAction
    
    /// An integer value to set time delay in ms
    var autoDismissDelay: Float
    
    /// - Parameters:
    ///   - layoutDict: A dictionary for the type LayoutInfo.
    init(withDict layoutDict: Dictionary<String,Any>) {
        
        if let styleDict = layoutDict[constant_style] as? Dictionary<String,Any> {
        
            self.style = LeapStyle(withDict: styleDict)
        
        } else {
            
            self.style = LeapStyle(withDict: [:])
        }
        
        if let dismissAction = layoutDict[constant_dismissAction] as? Dictionary<String,Any> {
            
            self.dismissAction = LeapDismissAction(withDict: dismissAction)
        
        } else {
            
            self.dismissAction = LeapDismissAction(withDict: [:])
        }
        
        if let enterAnimation = layoutDict[constant_enterAnimation] as? String {
            
            self.enterAnimation = enterAnimation
        }
        
        if let exitAnimation = layoutDict[constant_exitAnimation] as? String {
            
            self.exitAnimation = exitAnimation
        }
        
        if let alignment = layoutDict[constant_alignment] as? String {
            
            self.layoutAlignment = alignment
        }
        
        self.autoDismissDelay = (layoutDict[constant_autoDismissDelay] as? Float ?? 0)/1000
    }
}

class LeapDismissAction {
    
    var outsideDismiss: Bool?
    
    var dismissOnAnchorClick: Bool?
    
    /// - Parameters:
    ///   - dismissDict: A dictionary for the type DismissAction.
    init(withDict dismissDict: Dictionary<String,Any>) {
        
        if let outsideDismiss = dismissDict[constant_outsideDismiss] as? Bool {
            
            self.outsideDismiss = outsideDismiss
        }
        
        if let dismissOnAnchorClick = dismissDict[constant_dismissOnAnchorClick] as? Bool {
            
            self.dismissOnAnchorClick = dismissOnAnchorClick
        }
    }
}

/// Types of Alignments for the AUIComponent
enum LeapAlignmentType: String, CaseIterable {
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
enum LeapLayoutAnimationType: String, CaseIterable {
    case slideLeft = "slide_left"
    case slideTop = "slide_up"
    case slideRight = "slide_right"
    case slideBottom = "slide_down"
    case fadeIn = "fade_in"
    case fadeOut = "fade_out"
    case zoomIn = "zoom_in"
    case zoomOut = "zoom_out"
}
