//
//  JinyPopup.swift
//  JinyDemo
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyPopup - A Web KeyWindowAssist AUI Component class to show a popup on a window.
public class JinyPopup: JinyKeyWindowAssist {
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showPopup() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 14 // hardcoded value
        
        configureOverlayView()
        
        configureWebView()
        
        configureWebViewForPopup()
                    
        show()
    }
    
    /// This is a custom configuration of constraints for the Popup component.
    private func configureWebViewForPopup() {
        
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -10))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 10))
    }
    
    /// Set height constraint for the popup.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    private func configureHeightConstraint(height: CGFloat) {
        
        self.webView.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height))
    }
    
    public override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (value, error) in
            if let height = value as? CGFloat {
                                
                self?.configureHeightConstraint(height: height)
                
                self?.configureJinyIconView(superView: self!, toItemView: self!.webView, alignmentType: .bottom)
            }
        })
    }
}
