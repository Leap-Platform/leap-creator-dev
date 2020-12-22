//
//  JinyCarousel.swift
//  JinyAUI
//
//  Created by Ajay S on 17/12/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public enum JinyCarouselType: String {
    case fullScreen = "FULLSCREEN"
    case overlay = "OVERLAY"
}

/// JinyCarousel - A Web KeyWindowAssist AUI Component class to show a fullscreen or overlay assist on a window.
public class JinyCarousel: JinyKeyWindowAssist {
    
    var type: JinyCarouselType = .fullScreen // default
    
    private var heightConstraint: NSLayoutConstraint?
    
    /// call the method to configure constraints for the component and to load the content to display.
    public func showCarousel() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        configureOverlayView()
        
        configureWebView()
        
        configureCarousel()
                
        show()
    }
    
    private func configureCarousel() {
        
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
                
        if let type = self.assistInfo?.extraProps?.props["carouselType"] as? String {
            
            self.type = JinyCarouselType(rawValue: type) ?? .fullScreen
        }
        
        if type == .overlay {
            
            self.webView.isOpaque = false
            
        } else {
            
            self.webView.isOpaque = true
            configureWebViewForFullScreenCarousel()
        }
    }
    
    /// This is a custom configuration of constraints for the Carousel type.
    private func configureWebViewForFullScreenCarousel() {
      
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
    
    /// This is a custom configuration of constraints for the Carousel type.
    private func configureWebViewForOverlayCarousel(height: CGFloat) {

        webView.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height))
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
        
        if type == .fullScreen {
        
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
            
        } else {
            
            var attributeType1: NSLayoutConstraint.Attribute = .leading
            
            let attributeType2: NSLayoutConstraint.Attribute = .top
            
            let attributeType3: NSLayoutConstraint.Attribute = .bottom
                            
            var horizontalDistance: CGFloat = self.jinyIconView.iconGap
            
            let verticalDistance: CGFloat = self.jinyIconView.iconGap
            
            if !(iconInfo?.isLeftAligned ?? false) {
                            
                attributeType1 = .trailing
                
                horizontalDistance = -self.jinyIconView.iconGap
            }
                    
            superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: horizontalDistance))
            
            superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: verticalDistance))
        }
        
        jinyIconView.configureIconButon()
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if type == .overlay {
        
        self.webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                if complete != nil {
                    self.webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                        DispatchQueue.main.async {
                            if let height = height as? CGFloat {
                                self.configureWebViewForOverlayCarousel(height: height)
                            }
                        }
                   })
                }
            })
        }
        
        if type == .fullScreen {
        
           configureJinyIconView(superView: webView, toItemView: webView, alignmentType: .top)
            
        } else {
            
           configureJinyIconView(superView: self, toItemView: webView, alignmentType: .top)
        }
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
