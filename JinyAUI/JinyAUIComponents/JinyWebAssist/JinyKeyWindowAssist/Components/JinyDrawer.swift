//
//  JinyDrawer.swift
//  JinyDemo
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyDrawer - A Web KeyWindowAssist AUI Component class to show a drawe over a window.
public class JinyDrawer: JinyKeyWindowAssist {
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showDrawer() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 14 // hardcoded value
        
        configureOverlayView()
        
        if assistInfo?.layoutInfo?.layoutAlignment == nil {
            
           assistInfo?.layoutInfo?.layoutAlignment = JinyAlignmentType.left.rawValue
        }
        
        configureWebView()
        
        configureWebViewForDrawer()
        
        setAnimationType()
        
        show()
    }
    
    private func setAnimationType() {
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case JinyAlignmentType.left.rawValue:
            
            self.assistInfo?.layoutInfo?.enterAnimation = "slide_right"
            
            self.assistInfo?.layoutInfo?.exitAnimation = "slide_left"
            
        case JinyAlignmentType.right.rawValue:
            
            self.assistInfo?.layoutInfo?.enterAnimation = "slide_left"
            
            self.assistInfo?.layoutInfo?.exitAnimation = "slide_right"
            
        default:
            
            self.assistInfo?.layoutInfo?.enterAnimation = "slide_right"
            
            self.assistInfo?.layoutInfo?.exitAnimation = "slide_left"
        }
    }
    
    /// This is a custom configuration of constraints for the Drawer component.
    private func configureWebViewForDrawer() {
      
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
            
            case JinyAlignmentType.left.rawValue:
            
            configureConstraintsForLeftAlignment()
            
            case JinyAlignmentType.right.rawValue:
            
            configureConstraintsForRightAlignment()
                  
            default:
            
            configureConstraintsForLeftAlignment()
        }
    }
    
    /// Configuration of constraints for left alignment.
    private func configureConstraintsForLeftAlignment() {
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.8, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
    
    /// Configuration of constraints for right alignment.
    private func configureConstraintsForRightAlignment() {
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.8, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        // Support Constraint
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
    }
    
    override func configureJinyIconView(superView: UIView, toItemView: UIView, alignmentType: JinyAlignmentType) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(jinyIconView)
        
        jinyIconView.htmlUrl = iconInfo?.htmlUrl
        
        jinyIconView.tapGestureRecognizer.addTarget(self, action: #selector(jinyIconButtonTapped))
        
        jinyIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
                
        self.jinyIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        var attributeType2: NSLayoutConstraint.Attribute = .trailing
                
        var attributeType3: NSLayoutConstraint.Attribute = .bottom
        
        var horizontalDistance: CGFloat = self.jinyIconView.iconGap
        
        var verticalDistance: CGFloat = -self.jinyIconView.iconGap
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
            
            case JinyAlignmentType.right.rawValue:
            
                attributeType1 = .trailing
                
                attributeType2 = .leading
            
                horizontalDistance = -self.jinyIconView.iconGap
                  
            default: print("")
        }
        
        if alignmentType == .top {
                        
            attributeType3 = .top
            
            verticalDistance = self.jinyIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType2, multiplier: 1, constant: horizontalDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType3, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: verticalDistance))
        
        jinyIconView.configureIconButton()
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        configureJinyIconView(superView: self, toItemView: webView, alignmentType: .bottom)
    }
}
