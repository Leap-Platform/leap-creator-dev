//
//  JinyFullScreen.swift
//  JinyDemo
//
//  Created by mac on 10/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyFullScreen - A Web KeyWindowAssist AUI Component class to show a fullscreen assist on a window.
public class JinyFullScreen: JinyKeyWindowAssist {
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showFullScreen() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
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
    
    override func configureJinyIconView(superView: UIView, toItemView: UIView, alignmentType: JinyAlignmentType) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(jinyIconView)
        
        jinyIconView.htmlUrl = iconInfo?.htmlUrl ?? ""
        
        jinyIconView.tapGestureRecognizer.addTarget(self, action: #selector(jinyIconButtonTapped))
        
        jinyIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
                
        self.jinyIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        let attributeType2: NSLayoutConstraint.Attribute = .top
                        
        var horizontalDistance: CGFloat = self.jinyIconView.iconGap
        
        let verticalDistance: CGFloat = 4*self.jinyIconView.iconGap
        
        if !(iconInfo?.isLeftAligned ?? false) {
                        
            attributeType1 = .trailing
            
            horizontalDistance = -self.jinyIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: horizontalDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType2, multiplier: 1, constant: verticalDistance))
        
        jinyIconView.configureIconButon()
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        configureJinyIconView(superView: webView, toItemView: webView, alignmentType: .top)
    }
    
    public override func performEnterAnimation(animation: String) {
                
        self.alpha = 0
        
        jinyIconView.alpha = 0
        
        self.webView.alpha = 0
        
        self.webView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.webView.transform = CGAffineTransform.identity
            
            UIView.animate(withDuration: 0.05) {
                
               self.alpha = 1
            }
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.1) {
                
                self.webView.alpha = 1
                                
                self.jinyIconView.alpha = 1
                
                self.delegate?.didPresentAssist()
            }
        }
    }
}
