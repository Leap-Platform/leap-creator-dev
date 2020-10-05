//
//  JinyDrawer.swift
//  AUIComponents
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public class JinyDrawer: JinyKeyWindowAssist {
    
    public init(withDict assistDict: Dictionary<String,Any>) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showDrawer() {
        
        configureOverlayView()
        
        configureWebView()
        
        configureWebViewForDrawer()
        
        show()
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
            
        case JinyAlignmentType.center.rawValue:
            
            configureConstraintsForCenterAlignment()
                  
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
    
    /// Configuration of constraints for center alignment.
    private func configureConstraintsForCenterAlignment() {
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.8, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}
