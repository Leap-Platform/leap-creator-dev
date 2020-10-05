//
//  JinyPopup.swift
//  AUIComponents
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public class JinyPopup: JinyKeyWindowAssist {
    
    public init(withDict assistDict: Dictionary<String,Any>) {
        super.init(frame: CGRect.zero)
        
        self.assistInfo = AssistInfo(withDict: assistDict)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showPopup() {
        
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
    private func configureHeightConstraint(height: CGFloat) {
        
        self.webView.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height))
    }
    
    public override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (value, error) in
            if let height = value as? CGFloat {
                                
                self?.configureHeightConstraint(height: height)
            }
        })
    }
}
