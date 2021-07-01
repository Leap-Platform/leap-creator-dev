//
//  LeapFullScreen.swift
//  LeapAUI
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapFullScreen - A Web KeyWindowAssist AUI Component class to show a fullscreen assist on a window.
class LeapFullScreen: LeapKeyWindowAssist {
    
    /// call the method to configure constraints for the component and to load the content to display.
    func showFullScreen() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        configureOverlayView()
        
        // exclusive to FullScreen, comment this to get color from config.
        self.backgroundColor = .clear //  hardcoded value
        
        configureWebView()
        
        configureWebViewForFullScreen()
        
        show()
    }
    
    /// This is a custom configuration of constraints for the FullScreen component.
    func configureWebViewForFullScreen() {
      
        // Setting Constraints to WebView
        
        webviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func configureLeapIconView(superView: UIView, toItemView: UIView, alignmentType: LeapAlignmentType, cornerDistance: CGFloat = 0) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(leapIconView)
        
        leapIconView.htmlUrl = iconInfo?.htmlUrl
                
        leapIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
                
        self.leapIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        let attributeType2: NSLayoutConstraint.Attribute = .top
                        
        var horizontalDistance: CGFloat = self.leapIconView.iconGap
        
        let verticalDistance: CGFloat = 4*self.leapIconView.iconGap
        
        if !(iconInfo?.isLeftAligned ?? false) {
                        
            attributeType1 = .trailing
            
            horizontalDistance = -self.leapIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: horizontalDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType2, multiplier: 1, constant: verticalDistance))
        
        leapIconView.configureIconButton()
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        configureLeapIconView(superView: webView, toItemView: webviewContainer, alignmentType: .top)
    }
    
    override func performEnterAnimation(animation: String) {
                
        self.alpha = 0
        
        leapIconView.alpha = 0
        
        self.webView.alpha = 0
        
        self.webviewContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.webviewContainer.transform = CGAffineTransform.identity
            
            UIView.animate(withDuration: 0.05) {
                
               self.alpha = 1
            }
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.1) {
                
                self.webView.alpha = 1
                                
                self.leapIconView.alpha = 1                
            }
        }
    }
}
