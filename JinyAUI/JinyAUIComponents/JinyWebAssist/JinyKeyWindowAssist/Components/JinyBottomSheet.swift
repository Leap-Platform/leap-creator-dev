//
//  JinyBottomSheet.swift
//  AUIComponents
//
//  Created by mac on 11/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public class JinyBottomSheet: JinyKeyWindowAssist {
        
    public init(withDict assistDict: Dictionary<String,Any>) {
        super.init(frame: CGRect.zero)
                
        var assistDict = assistDict
        
        if let layoutInfo = assistDict["layoutInfo"] as? Dictionary<String, Any> {
            
           var layoutInfo = layoutInfo
            
           layoutInfo["alignment"] = "bottom"
            
           assistDict["layoutInfo"] = layoutInfo
        }
        
        self.assistInfo = AssistInfo(withDict: assistDict)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showBottomSheet() {
        
        configureOverlayView()
        
        configureWebView()
        
        configureWebViewForBottomSheet()
        
        show()
    }
    
    /// This is a custom configuration of constraints for the BottomSheet component.
    private func configureWebViewForBottomSheet() {
      
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        
        // Support Constraint
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .top, multiplier: 1, constant: 0))
    }
    
    /// Set height constraint for the bottomSheet.
    private func configureHeightConstraint(height: CGFloat) {
        
        let proportionalHeight = (((self.assistInfo?.layoutInfo?.style.maxHeight ?? 80.0) * Double(self.frame.height)) / 100)
        
        if height > 0 && height < CGFloat(proportionalHeight) {
            
           self.assistInfo?.layoutInfo?.style.maxHeight = (Double(height) / Double(self.frame.height)) * 100
        }
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: CGFloat((self.assistInfo?.layoutInfo?.style.maxHeight ?? 80.0)/100), constant: 0))
    }
    
    public override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (value, error) in
            if let height = value as? CGFloat {
                
                self?.configureHeightConstraint(height: height)
            }
        })
    }
}
