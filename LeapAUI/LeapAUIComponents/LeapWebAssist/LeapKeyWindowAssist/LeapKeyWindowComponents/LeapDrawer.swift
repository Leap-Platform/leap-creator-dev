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
        
        if UIDevice.current.hasNotch {
            
            if UIDevice.current.orientation == .landscapeLeft {
                
                assistInfo?.layoutInfo?.layoutAlignment = LeapAlignmentType.right.rawValue
                
            } else if UIDevice.current.orientation == .landscapeRight {
                
                assistInfo?.layoutInfo?.layoutAlignment = LeapAlignmentType.left.rawValue
            }
        }
        
        configureWebView()
        
        configureWebViewForDrawer()
        
        setAnimationType()
        
        show()
    }
    
    private func setAnimationType() {
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case LeapAlignmentType.left.rawValue:
            
            self.assistInfo?.layoutInfo?.enterAnimation = LeapLayoutAnimationType.slideRight.rawValue
            
            self.assistInfo?.layoutInfo?.exitAnimation = LeapLayoutAnimationType.slideLeft.rawValue
            
        case LeapAlignmentType.right.rawValue:
            
            self.assistInfo?.layoutInfo?.enterAnimation = LeapLayoutAnimationType.slideLeft.rawValue
            
            self.assistInfo?.layoutInfo?.exitAnimation = LeapLayoutAnimationType.slideRight.rawValue
            
        default:
            
            self.assistInfo?.layoutInfo?.enterAnimation = LeapLayoutAnimationType.slideRight.rawValue
            
            self.assistInfo?.layoutInfo?.exitAnimation = LeapLayoutAnimationType.slideLeft.rawValue
        }
    }
    
    /// This is a custom configuration of constraints for the Drawer component.
    private func configureWebViewForDrawer() {
      
        // Setting Constraints to WebView
        configureConstraints(alignmentType: LeapAlignmentType(rawValue: self.assistInfo?.layoutInfo?.layoutAlignment ?? LeapAlignmentType.left.rawValue) ?? .left)
        
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    /// Configuration of constraints based on alignmentType.
    private func configureConstraints(alignmentType: LeapAlignmentType) {
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let alignmentConstraint: NSLayoutConstraint = NSLayoutConstraint(item: webView, attribute: (alignmentType == .right ? .trailing : .leading), relatedBy: .equal, toItem: self, attribute: (alignmentType == .right ? .trailing : .leading), multiplier: 1, constant: 0)
        
        webView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        webView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        webView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidthSupported*0.8).isActive = true

        if UIApplication.shared.statusBarOrientation.isLandscape {
            
            widthConstraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.8, constant: 0)
            
        } else {
            
            widthConstraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.8, constant: 0)
        }
                
        widthConstraint?.priority = .defaultLow
        
        NSLayoutConstraint.activate([widthConstraint!, alignmentConstraint])
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
