//
//  JinyFullScreen.swift
//  AUIComponents
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public class JinyFullScreen: JinyKeyWindowAssist {
    
    public init(withDict assistDict: Dictionary<String,Any>) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showFullScreen() {
        
        configureOverlayView()
        
        configureWebView()
        
        configureWebViewForFullScreen()
        
        show()
    }
    
    /// This is a custom configuration of constraints for the FullScreen component.
    private func configureWebViewForFullScreen() {
      
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}
