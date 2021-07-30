//
//  LeapDrawer.swift
//  LeapAUI
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapDrawer - A Web KeyWindowAssist AUI Component class to show a drawe over a window.
class LeapDrawer: LeapKeyWindowAssist {
    
    /// call the method to configure constraints for the component and to load the content to display.
    func showDrawer() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 14 // hardcoded value
        
        configureOverlayView()
        
        if assistInfo?.layoutInfo?.layoutAlignment == nil {
            
           assistInfo?.layoutInfo?.layoutAlignment = LeapAlignmentType.left.rawValue
        }
        
        configureWebView()
        
        configureWebViewForDrawer()
        
        setAnimationType()
        
        show()
    }
    
    private func setAnimationType() {
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case LeapAlignmentType.left.rawValue:
            
            self.assistInfo?.layoutInfo?.enterAnimation = "slide_right"
            
            self.assistInfo?.layoutInfo?.exitAnimation = "slide_left"
            
        case LeapAlignmentType.right.rawValue:
            
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
            
            case LeapAlignmentType.left.rawValue:
            
            configureConstraintsForLeftAlignment()
            
            case LeapAlignmentType.right.rawValue:
            
            configureConstraintsForRightAlignment()
                  
            default:
            
            configureConstraintsForLeftAlignment()
        }
        
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
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
    }
    
    override func configureLeapIconView(superView: UIView, toItemView: UIView, alignmentType: LeapAlignmentType, cornerDistance: CGFloat = 0, heightDistance:CGFloat? = nil) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(leapIconView)
        
        leapIconView.htmlUrl = iconInfo?.htmlUrl
                
        leapIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
                
        self.leapIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        var attributeType2: NSLayoutConstraint.Attribute = .trailing
                
        var attributeType3: NSLayoutConstraint.Attribute = .bottom
        
        var horizontalDistance: CGFloat = self.leapIconView.iconGap
        
        var verticalDistance: CGFloat = -self.leapIconView.iconGap
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
            
            case LeapAlignmentType.right.rawValue:
            
                attributeType1 = .trailing
                
                attributeType2 = .leading
            
                horizontalDistance = -self.leapIconView.iconGap
                  
            default: print("")
        }
        
        if alignmentType == .top {
                        
            attributeType3 = .top
            
            verticalDistance = self.leapIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType2, multiplier: 1, constant: horizontalDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType3, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: verticalDistance))
        
        leapIconView.configureIconButton()
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        configureLeapIconView(superView: self, toItemView: webView, alignmentType: .bottom)
    }
}
