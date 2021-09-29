//
//  LeapPopup.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapPopup - A Web KeyWindowAssist AUI Component class to show a popup on a window.
class LeapPopup: LeapKeyWindowAssist {
        
    /// call the method to configure constraints for the component and to load the content to display.
    func showPopup() {
        
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
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -24))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 24))
        
        heightConstraint = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier:1 , constant: 0)
        
        NSLayoutConstraint.activate([heightConstraint!])
    }
    
    /// Set height constraint for the popup.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    private func configureHeightConstraint(height: CGFloat) {
        
        // heightToApply is the calculated height to avoid popup overflow / out of bounds if image is large
        let heightToApply = CGFloat(height) < (UIScreen.main.bounds.height - 96) ? CGFloat(height) : (UIScreen.main.bounds.height - 96)
        
        heightConstraint?.constant = heightToApply
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        self.configureLeapIconView(superView: self, toItemView: self.webView, alignmentType: .bottom)
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let height = rect[constant_height] else { return }
        self.configureHeightConstraint(height: CGFloat(height))
    }
}
